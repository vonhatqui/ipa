import SwiftUI

// MARK: - Card Container
public struct CardContainer<Content: View>: View {
    public let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Section Header
public struct SectionHeaderView: View {
    public let title: String
    
    public init(title: String) {
        self.title = title
    }
    
    public var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(AppTheme.textSecondary)
                .kerning(1.2)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Setting Toggle Row
public struct SettingToggleRow: View {
    public let title: String
    public let subtitle: String?
    @Binding public var isOn: Bool
    
    public init(title: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: Color.white))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Setting Slider Row
public struct SettingSliderRow: View {
    public let title: String
    public let subtitle: String?
    @Binding public var value: Double
    public let range: ClosedRange<Double>
    public let step: Double
    public let unit: String
    
    public init(
        title: String,
        subtitle: String? = nil,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double = 1,
        unit: String = ""
    ) {
        self.title = title
        self.subtitle = subtitle
        self._value = value
        self.range = range
        self.step = step
        self.unit = unit
    }
    
    public var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if let sub = subtitle {
                        Text(sub)
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                Text("\(Int(value))\(unit)")
                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.15))
                    .cornerRadius(6)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Divider Line
public struct CardDivider: View {
    public init() {}
    public var body: some View {
        Divider()
            .background(AppTheme.cardBorder)
            .padding(.horizontal, 16)
    }
}
