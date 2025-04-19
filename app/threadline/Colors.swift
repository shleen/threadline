import SwiftUI

extension Color {
    static let background = Color(red: 1.0, green: 0.992, blue: 0.96)
}

struct RGBColor {
    private var _red: Int
    private var _green: Int
    private var _blue: Int

    init(red: Int, green: Int, blue: Int) {
        self._red = red
        self._green = green
        self._blue = blue
    }

    var red: Int { _red }
    var green: Int { _green }
    var blue: Int { _blue }

    var color: Color {
        Color(red: Double(_red) / 255.0, green: Double(_green) / 255.0, blue: Double(_blue) / 255.0)
    }
}
