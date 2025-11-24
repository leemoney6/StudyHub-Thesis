import SwiftUI

struct GlassBlurView: UIViewRepresentable {
    var removeAllFilters: Bool = false
    
    func makeUIView(context: Context) -> GlassBlurViewHelper {
        return GlassBlurViewHelper(removeAllFilters: removeAllFilters)
    }
    
    func updateUIView(_ uiView: GlassBlurViewHelper, context: Context) {
        DispatchQueue.main.async {
        }
    }
}

#Preview {
    GlassBlurView()
        .padding(15)
}
