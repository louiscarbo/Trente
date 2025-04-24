//
//  TrenteWidgetBundle.swift
//  TrenteWidget
//
//  Created by Louis Carbo Estaque on 23/04/2025.
//

import WidgetKit
import SwiftUI

@main
struct TrenteWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthRecapWidget()
        CategoryRemainingWidget()
    }
}
