import SpriteKit
import SwiftUI
import UIKit

struct WoodIconView: View {
    let wood: WoodType

    var body: some View {
        Canvas { context, size in
            WoodCanvasRenderer.draw(wood: wood, context: &context, size: size)
        }
        .aspectRatio(2.15, contentMode: .fit)
        .accessibilityLabel(wood.name)
    }
}

private enum WoodCanvasRenderer {
    static func draw(wood: WoodType, context: inout GraphicsContext, size: CGSize) {
        let bark = Color(wood.barkTint)
        let light = bark.opacity(0.72)
        let glow = Color(wood.flameTint)
        let w = size.width
        let h = size.height

        switch wood.visualKind {
        case .splitLog:
            context.fill(Path(roundedRect: CGRect(x: w * 0.08, y: h * 0.28, width: w * 0.78, height: h * 0.43), cornerRadius: h * 0.14), with: .color(bark))
            context.fill(Path(ellipseIn: CGRect(x: w * 0.03, y: h * 0.28, width: w * 0.25, height: h * 0.43)), with: .color(Color(red: 0.86, green: 0.60, blue: 0.33)))
            grain(context: &context, size: size, color: .black.opacity(0.32))
        case .charcoal:
            polygon([[0.12,0.68],[0.20,0.26],[0.47,0.18],[0.52,0.64]], color: .black.opacity(0.92), context: &context, size: size)
            polygon([[0.39,0.72],[0.48,0.24],[0.72,0.30],[0.78,0.70]], color: Color(red: 0.10, green: 0.09, blue: 0.08), context: &context, size: size)
            polygon([[0.69,0.67],[0.76,0.34],[0.91,0.42],[0.86,0.73]], color: .black.opacity(0.80), context: &context, size: size)
            context.stroke(line(from: CGPoint(x: w*0.17,y:h*0.48), to: CGPoint(x:w*0.82,y:h*0.54)), with: .color(.orange.opacity(0.54)), lineWidth: 1.5)
        case .birchLog:
            context.fill(Path(roundedRect: CGRect(x:w*0.08,y:h*0.30,width:w*0.80,height:h*0.40),cornerRadius:h*0.18),with:.color(Color(red:0.88,green:0.85,blue:0.74)))
            for x: CGFloat in [0.25,0.43,0.64,0.77] { context.fill(rectPath(CGRect(x:w*x,y:h*0.32,width:w*0.025,height:h*0.35)),with:.color(.black.opacity(0.52))) }
            context.fill(Path(ellipseIn:CGRect(x:w*0.03,y:h*0.30,width:w*0.20,height:h*0.40)),with:.color(Color(red:0.72,green:0.52,blue:0.29)))
        case .twigBundle:
            for i in 0..<6 {
                let y = h * (0.28 + CGFloat(i) * 0.075)
                var p = Path(); p.move(to:CGPoint(x:w*0.10,y:y)); p.addLine(to:CGPoint(x:w*0.90,y:y-h*0.13+CGFloat(i%2)*h*0.07))
                context.stroke(p,with:.color(i.isMultiple(of:2) ? bark : light),style:StrokeStyle(lineWidth:max(3,h*0.075),lineCap:.round))
            }
            context.fill(rectPath(CGRect(x:w*0.47,y:h*0.19,width:w*0.07,height:h*0.61)),with:.color(.orange.opacity(0.72)))
        case .bamboo:
            for i in 0..<3 {
                let y = h * (0.23 + CGFloat(i) * 0.21)
                context.fill(Path(roundedRect:CGRect(x:w*0.08,y:y,width:w*0.84,height:h*0.17),cornerRadius:h*0.08),with:.color(Color(red:0.48,green:0.58,blue:0.18)))
                for x: CGFloat in [0.31,0.60,0.82] { context.fill(rectPath(CGRect(x:w*x,y:y,width:w*0.018,height:h*0.17)),with:.color(.yellow.opacity(0.55))) }
            }
        case .nutShells:
            let shells: [(CGFloat, CGFloat, CGFloat)] = [(0.18,0.32,0.36),(0.46,0.22,0.42),(0.68,0.36,0.33)]
            for (x,y,s) in shells {
                context.fill(Path(ellipseIn:CGRect(x:w*x,y:h*y,width:w*s,height:h*s*1.35)),with:.color(bark))
                context.stroke(Path(ellipseIn:CGRect(x:w*(x+0.06),y:h*(y+0.08),width:w*(s-0.12),height:h*(s*1.35-0.16))),with:.color(.orange.opacity(0.32)),lineWidth:2)
            }
        case .twistedRoot:
            for offset: CGFloat in [-0.11,0,0.12] {
                var p=Path(); p.move(to:CGPoint(x:w*0.08,y:h*(0.55+offset))); p.addCurve(to:CGPoint(x:w*0.90,y:h*(0.43-offset)),control1:CGPoint(x:w*0.32,y:h*(0.04+offset)),control2:CGPoint(x:w*0.62,y:h*(0.92-offset)))
                context.stroke(p,with:.color(offset == 0 ? bark : light),style:StrokeStyle(lineWidth:max(4,h*0.10),lineCap:.round))
            }
        case .darkTimber:
            context.fill(Path(roundedRect:CGRect(x:w*0.08,y:h*0.25,width:w*0.84,height:h*0.50),cornerRadius:4),with:.color(Color(red:0.12,green:0.16,blue:0.19)))
            context.stroke(rectPath(CGRect(x:w*0.08,y:h*0.25,width:w*0.84,height:h*0.50)),with:.color(.blue.opacity(0.42)),lineWidth:2)
            grain(context:&context,size:size,color:.white.opacity(0.18))
        case .dragonCoal:
            polygon([[0.08,0.68],[0.18,0.19],[0.43,0.35],[0.50,0.76]],color:Color(red:0.20,green:0.02,blue:0.04),context:&context,size:size)
            polygon([[0.36,0.72],[0.52,0.13],[0.72,0.30],[0.78,0.75]],color:Color(red:0.31,green:0.03,blue:0.10),context:&context,size:size)
            polygon([[0.68,0.68],[0.80,0.28],[0.94,0.48],[0.86,0.78]],color:.black.opacity(0.88),context:&context,size:size)
            context.stroke(line(from:CGPoint(x:w*0.18,y:h*0.48),to:CGPoint(x:w*0.84,y:h*0.55)),with:.color(glow.opacity(0.88)),lineWidth:2)
        case .crystalBranch:
            context.stroke(line(from:CGPoint(x:w*0.06,y:h*0.67),to:CGPoint(x:w*0.92,y:h*0.32)),with:.color(bark),style:StrokeStyle(lineWidth:max(4,h*0.09),lineCap:.round))
            let crystals: [(Double, Double)] = [(0.28,0.48),(0.50,0.40),(0.72,0.31)]
            for (x,y) in crystals {
                polygon([[x,y-0.20],[x+0.10,y],[x,y+0.20],[x-0.10,y]],color:glow.opacity(0.90),context:&context,size:size)
            }
        }
    }

    private static func grain(context: inout GraphicsContext, size: CGSize, color: Color) {
        for y: CGFloat in [0.40,0.52,0.62] { context.stroke(line(from:CGPoint(x:size.width*0.25,y:size.height*y),to:CGPoint(x:size.width*0.82,y:size.height*(y-0.04))),with:.color(color),lineWidth:1) }
    }

    private static func line(from: CGPoint, to: CGPoint) -> Path { var p=Path(); p.move(to:from); p.addLine(to:to); return p }

    private static func rectPath(_ rect:CGRect)->Path { var p=Path(); p.addRect(rect); return p }

    private static func polygon(_ points:[[Double]],color:Color,context:inout GraphicsContext,size:CGSize) {
        guard let first=points.first else{return}; var p=Path(); p.move(to:CGPoint(x:size.width*CGFloat(first[0]),y:size.height*CGFloat(first[1]))); for q in points.dropFirst(){p.addLine(to:CGPoint(x:size.width*CGFloat(q[0]),y:size.height*CGFloat(q[1])))}; p.closeSubpath(); context.fill(p,with:.color(color))
    }
}

enum WoodSpriteFactory {
    static func makeNode(for wood: WoodType, size: CGSize) -> SKNode {
        let parent=SKNode()
        parent.name="thrown-wood"
        let bark=UIColor(red:CGFloat(wood.barkTint.red),green:CGFloat(wood.barkTint.green),blue:CGFloat(wood.barkTint.blue),alpha:1)
        let glow=UIColor(red:CGFloat(wood.flameTint.red),green:CGFloat(wood.flameTint.green),blue:CGFloat(wood.flameTint.blue),alpha:1)
        func addRect(_ rect:CGSize,_ pos:CGPoint,_ color:UIColor,_ radius:CGFloat=5,_ angle:CGFloat=0){let n=SKShapeNode(rectOf:rect,cornerRadius:radius);n.fillColor=color;n.strokeColor=color.withAlphaComponent(0.45);n.position=pos;n.zRotation=angle;parent.addChild(n)}
        func addCircle(_ radius:CGFloat,_ pos:CGPoint,_ color:UIColor){let n=SKShapeNode(circleOfRadius:radius);n.fillColor=color;n.strokeColor=color.withAlphaComponent(0.45);n.position=pos;parent.addChild(n)}
        switch wood.visualKind {
        case .splitLog:
            addRect(CGSize(width:size.width*0.78,height:size.height*0.48),.zero,bark,size.height*0.13); addCircle(size.height*0.23,CGPoint(x:-size.width*0.39,y:0),UIColor(red:0.83,green:0.56,blue:0.29,alpha:1))
        case .charcoal:
            for i in -1...1 { addRect(CGSize(width:size.width*0.27,height:size.height*0.62),CGPoint(x:CGFloat(i)*size.width*0.25,y:CGFloat(abs(i))*-4),UIColor(white:0.07+CGFloat(i+1)*0.025,alpha:1),3,CGFloat(i)*0.16) }
        case .birchLog:
            addRect(CGSize(width:size.width*0.82,height:size.height*0.46),.zero,UIColor(red:0.86,green:0.83,blue:0.72,alpha:1),size.height*0.18); for i in -2...2 { addRect(CGSize(width:3,height:size.height*0.40),CGPoint(x:CGFloat(i)*size.width*0.14,y:0),.black,1) }
        case .twigBundle:
            for i in -2...2 { addRect(CGSize(width:size.width*0.86,height:5),CGPoint(x:0,y:CGFloat(i)*7),i.isMultiple(of:2) ? bark : bark.withAlphaComponent(0.78),3,CGFloat(i)*0.035) }; addRect(CGSize(width:8,height:size.height*0.72),.zero,.systemOrange,2)
        case .bamboo:
            for i in -1...1 { addRect(CGSize(width:size.width*0.84,height:size.height*0.18),CGPoint(x:0,y:CGFloat(i)*size.height*0.22),UIColor(red:0.46,green:0.56,blue:0.16,alpha:1),size.height*0.09); for x in [-0.24,0.05,0.31] { addRect(CGSize(width:3,height:size.height*0.18),CGPoint(x:CGFloat(x)*size.width,y:CGFloat(i)*size.height*0.22),UIColor(red:0.78,green:0.70,blue:0.22,alpha:1),1) } }
        case .nutShells:
            addCircle(size.height*0.26,CGPoint(x:-size.width*0.22,y:-3),bark); addCircle(size.height*0.29,CGPoint(x:0,y:4),bark.withAlphaComponent(0.92)); addCircle(size.height*0.23,CGPoint(x:size.width*0.22,y:-5),bark)
        case .twistedRoot:
            for i in -1...1 {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: -size.width * 0.43, y: CGFloat(i) * 8))
                path.addCurve(
                    to: CGPoint(x: size.width * 0.43, y: CGFloat(-i) * 8),
                    control1: CGPoint(x: -size.width * 0.18, y: CGFloat(i) * 28),
                    control2: CGPoint(x: size.width * 0.18, y: CGFloat(-i) * 28)
                )
                let node = SKShapeNode(path: path)
                node.strokeColor = i == 0 ? bark : bark.withAlphaComponent(0.72)
                node.lineWidth = size.height * 0.12
                node.lineCap = .round
                parent.addChild(node)
            }
        case .darkTimber:
            addRect(CGSize(width:size.width*0.88,height:size.height*0.54),.zero,UIColor(red:0.10,green:0.14,blue:0.17,alpha:1),3); addRect(CGSize(width:size.width*0.76,height:2),CGPoint(x:0,y:5),glow.withAlphaComponent(0.55),1)
        case .dragonCoal:
            for i in -1...1 { let n=SKShapeNode(path:diamondPath(width:size.width*0.30,height:size.height*0.72));n.fillColor=UIColor(red:0.18+CGFloat(i+1)*0.05,green:0.01,blue:0.04,alpha:1);n.strokeColor=glow.withAlphaComponent(0.70);n.position=CGPoint(x:CGFloat(i)*size.width*0.25,y:CGFloat(abs(i))*-4);n.zRotation=CGFloat(i)*0.13;parent.addChild(n) }
        case .crystalBranch:
            addRect(CGSize(width: size.width * 0.88, height: 7), .zero, bark, 3, -0.18)
            for i in -1...1 {
                let node = SKShapeNode(
                    path: diamondPath(width: size.width * 0.17, height: size.height * 0.48)
                )
                node.fillColor = glow.withAlphaComponent(0.88)
                node.strokeColor = .white
                node.position = CGPoint(x: CGFloat(i) * size.width * 0.25, y: CGFloat(-i) * 5)
                parent.addChild(node)
            }
        }
        return parent
    }

    static func physicsSize(for wood:WoodType,base:CGSize)->CGSize {
        switch wood.visualKind { case .charcoal,.nutShells,.dragonCoal:return CGSize(width:base.width*0.78,height:base.height*0.72); case .twigBundle,.bamboo,.crystalBranch:return CGSize(width:base.width*0.90,height:base.height*0.48); default:return CGSize(width:base.width*0.84,height:base.height*0.52) }
    }

    private static func diamondPath(width:CGFloat,height:CGFloat)->CGPath { let p=CGMutablePath();p.move(to:CGPoint(x:0,y:height/2));p.addLine(to:CGPoint(x:width/2,y:0));p.addLine(to:CGPoint(x:0,y:-height/2));p.addLine(to:CGPoint(x:-width/2,y:0));p.closeSubpath();return p }
}
