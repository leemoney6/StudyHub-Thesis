import Foundation
import SwiftUI

// MARK: - Pomodoro Phase Enum
enum PomodoroPhase: String, CaseIterable, Codable {
    case focus = "focus"
    case shortBreak = "short break"
    case longBreak = "long break"
    
    var duration: TimeInterval {
        switch self {
        case .focus:      return 1500  // 25 min
        case .shortBreak: return 300   // 5 min
        case .longBreak:  return 900   // 15 min
        }
    }
    
    var title: String {
        switch self {
        case .focus:      return "Focus Time"
        case .shortBreak: return "Short Break"
        case .longBreak:  return "Long Break"
        }
    }
    
    var subtitle: String {
        switch self {
        case .focus:      return "Time to concentrate and get work done"
        case .shortBreak: return "Take a quick breather"
        case .longBreak:  return "Relax and recharge"
        }
    }
    
    var icon: String {
        switch self {
        case .focus:      return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak:  return "figure.walk"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .focus:      return [.red, .orange]
        case .shortBreak: return [.green, .mint]
        case .longBreak:  return [.blue, .cyan]
        }
    }
    
    var color: Color {
        colors.first ?? .blue
    }
    var completionMessage: String {
           switch self {
           case .focus:
               return "Great job! Time for a break."
           case .shortBreak:
               return "Break's over. Ready to focus?"
           case .longBreak:
               return "Long break complete. Let's get back to work!"
           }
       }
}
