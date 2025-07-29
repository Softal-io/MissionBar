//
//  SortDropdownView.swift
//  MissionBar
//
//  Created by Ram Patra on 29/07/2025.
//

import SwiftUI

protocol SortOption: CaseIterable, Hashable {
    var displayName: String { get }
}

struct SortDropdownView<T: SortOption>: View {
    @Binding var selectedOption: T
    @Binding var isAscending: Bool
    let options: [T]
    
    init(selectedOption: Binding<T>, isAscending: Binding<Bool>) {
        self._selectedOption = selectedOption
        self._isAscending = isAscending
        self.options = Array(T.allCases)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Sort option dropdown
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selectedOption = option
                    }) {
                        Text(option.displayName)
                    }
                }
            } label: {
                Text(selectedOption.displayName)
                    .font(.system(size: 12))
                .foregroundColor(.primary)
            }
            .menuStyle(.borderlessButton)
            .padding(.leading, 6)
            
            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 0.5)
                .padding(.vertical, 4)
            
            // Sort order toggle
            Button(action: {
                isAscending.toggle()
            }) {
                Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10))
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
            .padding(.trailing, 4)
            .help(isAscending ? "Sort descending" : "Sort ascending")
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .frame(height: 32) // Match SearchBoxView height
    }
}

// Extensions to make existing enums conform to SortOption protocol
extension ProcessSortOption: SortOption {}
extension AppSortOption: SortOption {} 

#Preview {
    SortDropdownView<AppSortOption>(selectedOption: .constant(.name), isAscending: .constant(true))
        .padding()
}
