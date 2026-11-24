//
//  HabitItem.swift
//  Profile
//
//  Created by Athanas Shauritanga on 04/10/2026.
//

import Foundation

struct HabitItem: Identifiable {

    let id = UUID()

    let title: String
    let time: String
    let icon: String
    let status: HabitStatus
}
