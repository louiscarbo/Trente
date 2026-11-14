import os
import sys

import numpy as np
from PIL import Image
from psd_tools import PSDImage

CAPTURE_SIZE = (2853, 2007)
DEFAULT_BEZEL_NAME = "iPhone Duo - Star White - Inner Partially Open Landscape.psd"
DEFAULT_BEZEL_DIRECTORY = "~/Pictures/Trente Store Assets/iPhone Duo"


def homography(source_points, destination_points):
    rows = []
    for (source_x, source_y), (destination_x, destination_y) in zip(source_points, destination_points):
        rows.append([source_x, source_y, 1, 0, 0, 0, -destination_x * source_x, -destination_x * source_y, -destination_x])
        rows.append([0, 0, 0, source_x, source_y, 1, -destination_y * source_x, -destination_y * source_y, -destination_y])
    _, _, right_vectors = np.linalg.svd(np.asarray(rows, dtype=np.float64))
    return right_vectors[-1].reshape(3, 3)


def layer_canvas(layer, canvas_size, mode):
    canvas = Image.new(mode, canvas_size, 0)
    canvas.paste(layer.topil().convert(mode), (layer.bbox[0], layer.bbox[1]))
    return canvas


def mask_canvas(layer, canvas_size):
    mask = layer.mask
    canvas = Image.new("L", canvas_size, mask.background_color)
    canvas.paste(mask.topil(), (mask.bbox[0], mask.bbox[1]))
    return np.asarray(canvas, dtype=np.float32) / 255


class Bezel:
    def __init__(self, path):
        psd = PSDImage.open(path)
        self.size = psd.size
        layers = {layer.name: layer for layer in psd.descendants()}
        self.hardware = np.asarray(layer_canvas(layers["Hardware"], self.size, "RGBA"), dtype=np.float32) / 255
        self.screen_mask = mask_canvas(layers["Screen Content"], self.size)
        reflection = layers["Screen Reflection"]
        curve_layer = layers["Luminosity"]
        self.reflection_amount = (
            mask_canvas(reflection, self.size)
            * mask_canvas(curve_layer, self.size)
            * (reflection.opacity / 255)
            * (curve_layer.opacity / 255)
        )
        curve_points = curve_layer.tagged_blocks.get_data(b"curv").data[0]
        self.curve_input = np.asarray([point[0] for point in curve_points], dtype=np.float32) / 255
        self.curve_output = np.asarray([point[1] for point in curve_points], dtype=np.float32) / 255
        warp = layers["Screen Content"].tagged_blocks.get_data(b"SoLd").data[b"filterFX"][b"filterFXList"][0][b"Fltr"]
        self.reference = warp[b"referenceRect"]
        self.vertices = [(point[b"Hrzn"].value, point[b"Vrtc"].value) for point in warp[b"vertices"]]
        self.warped_vertices = [(point[b"Hrzn"].value, point[b"Vrtc"].value) for point in warp[b"warpedVertices"]]
        self.quads = [[index.value for index in quad[b"indices"]] for quad in warp[b"quads"]]

    def warp(self, capture):
        left = self.reference[b"Left"].value
        top = self.reference[b"Top "].value
        scale_x = (self.reference[b"Rght"].value - left) / CAPTURE_SIZE[0]
        scale_y = (self.reference[b"Btom"].value - top) / CAPTURE_SIZE[1]
        warped = Image.new("RGB", self.size, 0)
        coverage = Image.new("L", self.size, 0)
        white = Image.new("L", CAPTURE_SIZE, 255)
        for quad in self.quads:
            source = [
                ((self.vertices[index][0] - left) / scale_x, (self.vertices[index][1] - top) / scale_y)
                for index in quad
            ]
            destination = [self.warped_vertices[index] for index in quad]
            inverse = homography(destination, source)
            coefficients = (inverse / inverse[2, 2]).flatten()[:8]
            source_xs = sorted(point[0] for point in source)
            crop = (max(0, int(source_xs[0]) - 2), 0, min(CAPTURE_SIZE[0], int(source_xs[-1]) + 3), CAPTURE_SIZE[1])
            shifted = coefficients.copy()
            shifted[0] -= crop[0] * coefficients[6]
            shifted[1] -= crop[0] * coefficients[7]
            shifted[2] -= crop[0]
            panel = capture.crop(crop).transform(self.size, Image.PERSPECTIVE, shifted, Image.BICUBIC)
            panel_mask = white.crop(crop).transform(self.size, Image.PERSPECTIVE, shifted, Image.BILINEAR)
            destination_xs = [point[0] for point in destination]
            band = Image.new("L", self.size, 0)
            band.paste(255, (int(round(min(destination_xs))), 0, int(round(max(destination_xs))), self.size[1]))
            panel_mask = Image.composite(panel_mask, Image.new("L", self.size, 0), band)
            warped.paste(panel, (0, 0), panel_mask)
            coverage.paste(255, (0, 0), panel_mask)
        return np.asarray(warped, dtype=np.float32) / 255, np.asarray(coverage, dtype=np.float32) / 255

    def compose(self, capture):
        content, coverage = self.warp(capture.convert("RGB").resize(CAPTURE_SIZE))
        amount = (coverage * self.screen_mask)[..., None]
        base = self.hardware[..., :3]
        screened = 1 - (1 - base) * (1 - content * amount)
        luminance = screened @ np.asarray([0.3, 0.59, 0.11], dtype=np.float32)
        target = np.interp(luminance, self.curve_input, self.curve_output)
        shifted = np.clip(screened + (target - luminance)[..., None], 0, 1)
        reflection = self.reflection_amount[..., None]
        result = screened * (1 - reflection) + shifted * reflection
        rgba = np.dstack([result, self.hardware[..., 3]])
        return Image.fromarray((rgba * 255 + 0.5).astype(np.uint8), "RGBA")


def bezel_path():
    override = os.environ.get("STORE_CAPTURE_DUO_BEZEL")
    path = os.path.expanduser(override) if override else os.path.join(os.path.expanduser(DEFAULT_BEZEL_DIRECTORY), DEFAULT_BEZEL_NAME)
    if not os.path.exists(path):
        sys.exit(
            f"Missing Apple bezel PSD: {path}\n"
            "Download Bezel-iPhone-Duo.dmg from Apple Design Resources, accept the licence, and copy\n"
            f"'{DEFAULT_BEZEL_NAME}' (inside the Photoshop folder) to {DEFAULT_BEZEL_DIRECTORY}, "
            "or point STORE_CAPTURE_DUO_BEZEL at it."
        )
    return path


def main():
    if len(sys.argv) < 4 or len(sys.argv) % 2 != 0:
        sys.exit("usage: fold-composite.py <output scale> <capture.png> <output.png> [<capture.png> <output.png> ...]")
    scale = float(sys.argv[1])
    pairs = sys.argv[2:]
    bezel = Bezel(bezel_path())
    for capture_path, output_path in zip(pairs[::2], pairs[1::2]):
        image = bezel.compose(Image.open(capture_path))
        image = image.crop(image.getbbox())
        if scale != 1:
            image = image.resize((round(image.size[0] * scale), round(image.size[1] * scale)), Image.LANCZOS)
        image.save(output_path)
        print(output_path, image.size)


if __name__ == "__main__":
    main()
