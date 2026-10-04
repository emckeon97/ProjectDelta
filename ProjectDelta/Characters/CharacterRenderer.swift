import SpriteKit
import UIKit

/// Code-drawn 1930s rubber-hose cartoon characters. Pure vector SKShapeNode art —
/// no textures, no downloaded assets. Each node is ~120pt tall with its origin
/// at the feet center (children span y: 0 → ~120, x centered on 0).
enum CharacterRenderer {

    static func node(for id: String) -> SKNode {
        switch id {
        case "felix":  return felix()
        case "oswald": return oswald()
        case "popeye": return popeye()
        case "pooh":   return pooh()
        case "betty":  return betty()
        default:       return willie()
        }
    }

    // MARK: - Palette

    private static let ink   = SKColor.black
    private static let paper = SKColor.white
    private static let red   = SKColor(red: 0.82, green: 0.16, blue: 0.16, alpha: 1.0)
    private static let gold  = SKColor(red: 0.96, green: 0.76, blue: 0.30, alpha: 1.0)
    private static let honey = SKColor(red: 0.99, green: 0.88, blue: 0.62, alpha: 1.0)
    private static let tan   = SKColor(red: 0.98, green: 0.84, blue: 0.64, alpha: 1.0)
    private static let blue  = SKColor(red: 0.20, green: 0.38, blue: 0.82, alpha: 1.0)
    private static let brown = SKColor(red: 0.45, green: 0.28, blue: 0.16, alpha: 1.0)

    // MARK: - Shape helpers

    private static func shape(_ path: CGPath, fill: SKColor,
                              stroke: SKColor = .clear, lineWidth: CGFloat = 0) -> SKShapeNode {
        let node = SKShapeNode(path: path)
        node.fillColor = fill
        node.strokeColor = stroke
        node.lineWidth = lineWidth
        node.isAntialiased = true
        return node
    }

    private static func ellipse(center: CGPoint, size: CGSize, fill: SKColor,
                                stroke: SKColor = .clear, lineWidth: CGFloat = 0) -> SKShapeNode {
        let rect = CGRect(x: center.x - size.width / 2,
                          y: center.y - size.height / 2,
                          width: size.width, height: size.height)
        return shape(UIBezierPath(ovalIn: rect).cgPath, fill: fill, stroke: stroke, lineWidth: lineWidth)
    }

    private static func circle(center: CGPoint, radius: CGFloat, fill: SKColor,
                               stroke: SKColor = .clear, lineWidth: CGFloat = 0) -> SKShapeNode {
        ellipse(center: center, size: CGSize(width: radius * 2, height: radius * 2),
                fill: fill, stroke: stroke, lineWidth: lineWidth)
    }

    private static func strokePath(_ path: CGPath, color: SKColor, width: CGFloat) -> SKShapeNode {
        let node = SKShapeNode(path: path)
        node.strokeColor = color
        node.lineWidth = width
        node.lineCap = .round
        node.fillColor = .clear
        node.isAntialiased = true
        return node
    }

    private static func polyline(_ points: [CGPoint], color: SKColor, width: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        if let first = points.first {
            path.move(to: first)
            for p in points.dropFirst() { path.addLine(to: p) }
        }
        return strokePath(path, color: color, width: width)
    }

    private static func polygon(_ points: [CGPoint], fill: SKColor) -> SKShapeNode {
        let path = CGMutablePath()
        if let first = points.first {
            path.move(to: first)
            for p in points.dropFirst() { path.addLine(to: p) }
            path.closeSubpath()
        }
        return shape(path, fill: fill)
    }

    private static func roundedRect(_ rect: CGRect, radius: CGFloat, fill: SKColor) -> SKShapeNode {
        shape(UIBezierPath(roundedRect: rect, cornerRadius: radius).cgPath, fill: fill)
    }

    /// Classic 1930s pie-cut eye: white oval, black wedge, offset pupil.
    private static func pieEye(center: CGPoint, size: CGSize) -> SKNode {
        let group = SKNode()
        group.addChild(ellipse(center: center, size: size, fill: paper, stroke: ink, lineWidth: 1.5))
        let w = size.width / 2, h = size.height / 2
        group.addChild(polygon([
            center,
            CGPoint(x: center.x - w * 0.75, y: center.y + h * 0.45),
            CGPoint(x: center.x + w * 0.05, y: center.y + h * 0.95),
        ], fill: ink))
        group.addChild(circle(center: CGPoint(x: center.x + 1, y: center.y - 2),
                              radius: min(w, h) * 0.26, fill: ink))
        return group
    }

    private static func glove(at point: CGPoint) -> SKShapeNode {
        circle(center: point, radius: 8, fill: paper, stroke: ink, lineWidth: 1.5)
    }

    // MARK: - Steamboat Willie

    private static func willie() -> SKNode {
        let n = SKNode()
        // Big shoes
        n.addChild(ellipse(center: CGPoint(x: -14, y: 9), size: CGSize(width: 30, height: 17), fill: ink))
        n.addChild(ellipse(center: CGPoint(x: 14, y: 9), size: CGSize(width: 30, height: 17), fill: ink))
        // Thin legs
        n.addChild(polyline([CGPoint(x: -10, y: 15), CGPoint(x: -10, y: 44)], color: ink, width: 5))
        n.addChild(polyline([CGPoint(x: 10, y: 15), CGPoint(x: 10, y: 44)], color: ink, width: 5))
        // Red shorts
        n.addChild(polygon([CGPoint(x: -19, y: 42), CGPoint(x: 19, y: 42),
                            CGPoint(x: 14, y: 64), CGPoint(x: -14, y: 64)], fill: red))
        // Body
        n.addChild(ellipse(center: CGPoint(x: 0, y: 74), size: CGSize(width: 38, height: 36), fill: ink))
        // Arms + white gloves
        n.addChild(polyline([CGPoint(x: -17, y: 78), CGPoint(x: -30, y: 62)], color: ink, width: 5))
        n.addChild(polyline([CGPoint(x: 17, y: 78), CGPoint(x: 30, y: 62)], color: ink, width: 5))
        n.addChild(glove(at: CGPoint(x: -33, y: 60)))
        n.addChild(glove(at: CGPoint(x: 33, y: 60)))
        // Round ears
        n.addChild(circle(center: CGPoint(x: -19, y: 112), radius: 10, fill: ink))
        n.addChild(circle(center: CGPoint(x: 19, y: 112), radius: 10, fill: ink))
        // Head
        n.addChild(ellipse(center: CGPoint(x: 0, y: 94), size: CGSize(width: 42, height: 38), fill: ink))
        // White muzzle
        n.addChild(ellipse(center: CGPoint(x: 0, y: 86), size: CGSize(width: 26, height: 18), fill: paper))
        // Pie-cut eyes
        n.addChild(pieEye(center: CGPoint(x: -9, y: 102), size: CGSize(width: 12, height: 16)))
        n.addChild(pieEye(center: CGPoint(x: 9, y: 102), size: CGSize(width: 12, height: 16)))
        // Nose + smile
        n.addChild(ellipse(center: CGPoint(x: 0, y: 90), size: CGSize(width: 10, height: 7), fill: ink))
        n.addChild(polyline([CGPoint(x: -10, y: 80), CGPoint(x: -4, y: 77),
                             CGPoint(x: 4, y: 77), CGPoint(x: 10, y: 80)], color: ink, width: 2))
        return n
    }

    // MARK: - Felix the Cat

    private static func felix() -> SKNode {
        let n = SKNode()
        // Long curved tail
        n.addChild(polyline([CGPoint(x: 18, y: 50), CGPoint(x: 30, y: 56),
                             CGPoint(x: 36, y: 68), CGPoint(x: 30, y: 80)], color: ink, width: 9))
        // Feet
        n.addChild(ellipse(center: CGPoint(x: -12, y: 8), size: CGSize(width: 22, height: 14), fill: ink))
        n.addChild(ellipse(center: CGPoint(x: 12, y: 8), size: CGSize(width: 22, height: 14), fill: ink))
        // Body
        n.addChild(ellipse(center: CGPoint(x: 0, y: 48), size: CGSize(width: 42, height: 52), fill: ink))
        // Head
        n.addChild(circle(center: CGPoint(x: 0, y: 92), radius: 23, fill: ink))
        // Pointy ears
        n.addChild(polygon([CGPoint(x: -17, y: 106), CGPoint(x: -9, y: 126),
                            CGPoint(x: -2, y: 109)], fill: ink))
        n.addChild(polygon([CGPoint(x: 17, y: 106), CGPoint(x: 9, y: 126),
                            CGPoint(x: 2, y: 109)], fill: ink))
        // Huge white eyes
        n.addChild(ellipse(center: CGPoint(x: -10, y: 96), size: CGSize(width: 17, height: 23),
                           fill: paper, stroke: ink, lineWidth: 1))
        n.addChild(ellipse(center: CGPoint(x: 10, y: 96), size: CGSize(width: 17, height: 23),
                           fill: paper, stroke: ink, lineWidth: 1))
        n.addChild(circle(center: CGPoint(x: -10, y: 93), radius: 4.5, fill: ink))
        n.addChild(circle(center: CGPoint(x: 10, y: 93), radius: 4.5, fill: ink))
        // Wide trademark grin
        n.addChild(polyline([CGPoint(x: -17, y: 78), CGPoint(x: -8, y: 71),
                             CGPoint(x: 8, y: 71), CGPoint(x: 17, y: 78)], color: paper, width: 5))
        // Little arms
        n.addChild(polyline([CGPoint(x: -19, y: 58), CGPoint(x: -28, y: 48)], color: ink, width: 6))
        n.addChild(polyline([CGPoint(x: 19, y: 58), CGPoint(x: 28, y: 48)], color: ink, width: 6))
        return n
    }

    // MARK: - Oswald the Lucky Rabbit

    private static func oswald() -> SKNode {
        let n = SKNode()
        // Long floppy ears
        n.addChild(polyline([CGPoint(x: -10, y: 110), CGPoint(x: -20, y: 107),
                             CGPoint(x: -31, y: 99)], color: ink, width: 13))
        n.addChild(polyline([CGPoint(x: 10, y: 110), CGPoint(x: 20, y: 107),
                             CGPoint(x: 31, y: 99)], color: ink, width: 13))
        // Shoes + legs
        n.addChild(ellipse(center: CGPoint(x: -12, y: 8), size: CGSize(width: 24, height: 15), fill: ink))
        n.addChild(ellipse(center: CGPoint(x: 12, y: 8), size: CGSize(width: 24, height: 15), fill: ink))
        n.addChild(polyline([CGPoint(x: -9, y: 14), CGPoint(x: -9, y: 40)], color: ink, width: 5))
        n.addChild(polyline([CGPoint(x: 9, y: 14), CGPoint(x: 9, y: 40)], color: ink, width: 5))
        // Blue shorts
        n.addChild(polygon([CGPoint(x: -15, y: 40), CGPoint(x: 15, y: 40),
                            CGPoint(x: 12, y: 58), CGPoint(x: -12, y: 58)], fill: blue))
        // Body
        n.addChild(ellipse(center: CGPoint(x: 0, y: 68), size: CGSize(width: 34, height: 38), fill: ink))
        // Arms + gloves
        n.addChild(polyline([CGPoint(x: -15, y: 72), CGPoint(x: -27, y: 58)], color: ink, width: 5))
        n.addChild(polyline([CGPoint(x: 15, y: 72), CGPoint(x: 27, y: 58)], color: ink, width: 5))
        n.addChild(glove(at: CGPoint(x: -30, y: 56)))
        n.addChild(glove(at: CGPoint(x: 30, y: 56)))
        // Head + white face
        n.addChild(circle(center: CGPoint(x: 0, y: 94), radius: 20, fill: ink))
        n.addChild(ellipse(center: CGPoint(x: 0, y: 89), size: CGSize(width: 24, height: 17), fill: paper))
        n.addChild(pieEye(center: CGPoint(x: -8, y: 100), size: CGSize(width: 11, height: 15)))
        n.addChild(pieEye(center: CGPoint(x: 8, y: 100), size: CGSize(width: 11, height: 15)))
        n.addChild(ellipse(center: CGPoint(x: 0, y: 91), size: CGSize(width: 8, height: 6), fill: ink))
        return n
    }

    // MARK: - Popeye the Sailor

    private static func popeye() -> SKNode {
        let n = SKNode()
        // Big shoes
        n.addChild(ellipse(center: CGPoint(x: -13, y: 9), size: CGSize(width: 28, height: 17), fill: ink))
        n.addChild(ellipse(center: CGPoint(x: 13, y: 9), size: CGSize(width: 28, height: 17), fill: ink))
        // Legs (black pants)
        n.addChild(polyline([CGPoint(x: -9, y: 15), CGPoint(x: -9, y: 44)], color: ink, width: 8))
        n.addChild(polyline([CGPoint(x: 9, y: 15), CGPoint(x: 9, y: 44)], color: ink, width: 8))
        // Black sailor shirt torso
        n.addChild(ellipse(center: CGPoint(x: 0, y: 64), size: CGSize(width: 38, height: 42), fill: ink))
        // Red neckerchief
        n.addChild(polygon([CGPoint(x: -8, y: 86), CGPoint(x: 8, y: 86),
                            CGPoint(x: 0, y: 75)], fill: red))
        // Signature huge forearms
        n.addChild(ellipse(center: CGPoint(x: -27, y: 52), size: CGSize(width: 22, height: 36), fill: tan))
        n.addChild(ellipse(center: CGPoint(x: 27, y: 52), size: CGSize(width: 22, height: 36), fill: tan))
        n.addChild(circle(center: CGPoint(x: -27, y: 31), radius: 11, fill: tan,
                          stroke: ink, lineWidth: 1.5))
        n.addChild(circle(center: CGPoint(x: 27, y: 31), radius: 11, fill: tan,
                          stroke: ink, lineWidth: 1.5))
        // Upper arms
        n.addChild(polyline([CGPoint(x: -15, y: 74), CGPoint(x: -24, y: 64)], color: ink, width: 8))
        n.addChild(polyline([CGPoint(x: 15, y: 74), CGPoint(x: 24, y: 64)], color: ink, width: 8))
        // Head
        n.addChild(circle(center: CGPoint(x: 0, y: 100), radius: 18, fill: tan,
                          stroke: ink, lineWidth: 1.5))
        // Big nose
        n.addChild(circle(center: CGPoint(x: 2, y: 99), radius: 6, fill: tan, stroke: ink, lineWidth: 1.5))
        // Squinting eye: line + dot
        n.addChild(polyline([CGPoint(x: -11, y: 106), CGPoint(x: -2, y: 106)], color: ink, width: 2.5))
        n.addChild(circle(center: CGPoint(x: -6, y: 104), radius: 1.8, fill: ink))
        // Strong chin
        n.addChild(polyline([CGPoint(x: -8, y: 88), CGPoint(x: 0, y: 85),
                             CGPoint(x: 9, y: 88)], color: ink, width: 2))
        // White sailor cap
        n.addChild(ellipse(center: CGPoint(x: 0, y: 116), size: CGSize(width: 30, height: 12),
                           fill: paper, stroke: ink, lineWidth: 1.5))
        // Corncob pipe
        n.addChild(polyline([CGPoint(x: 8, y: 92), CGPoint(x: 17, y: 88)], color: brown, width: 3.5))
        n.addChild(circle(center: CGPoint(x: 18, y: 87), radius: 4, fill: brown))
        return n
    }

    // MARK: - Winnie the Pooh

    private static func pooh() -> SKNode {
        let n = SKNode()
        // Feet
        n.addChild(ellipse(center: CGPoint(x: -14, y: 8), size: CGSize(width: 24, height: 15), fill: gold))
        n.addChild(ellipse(center: CGPoint(x: 14, y: 8), size: CGSize(width: 24, height: 15), fill: gold))
        // Round body
        n.addChild(ellipse(center: CGPoint(x: 0, y: 52), size: CGSize(width: 62, height: 66), fill: gold))
        // Red shirt
        n.addChild(roundedRect(CGRect(x: -30, y: 54, width: 60, height: 32), radius: 10, fill: red))
        // Stubby arms
        n.addChild(ellipse(center: CGPoint(x: -34, y: 66), size: CGSize(width: 16, height: 28), fill: gold))
        n.addChild(ellipse(center: CGPoint(x: 34, y: 66), size: CGSize(width: 16, height: 28), fill: gold))
        // Head
        n.addChild(circle(center: CGPoint(x: 0, y: 102), radius: 21, fill: gold))
        // Round ears
        n.addChild(circle(center: CGPoint(x: -15, y: 118), radius: 8, fill: gold))
        n.addChild(circle(center: CGPoint(x: 15, y: 118), radius: 8, fill: gold))
        n.addChild(circle(center: CGPoint(x: -15, y: 118), radius: 3.5, fill: brown))
        n.addChild(circle(center: CGPoint(x: 15, y: 118), radius: 3.5, fill: brown))
        // Friendly face
        n.addChild(circle(center: CGPoint(x: -7, y: 104), radius: 2.5, fill: ink))
        n.addChild(circle(center: CGPoint(x: 7, y: 104), radius: 2.5, fill: ink))
        n.addChild(ellipse(center: CGPoint(x: 0, y: 96), size: CGSize(width: 18, height: 12), fill: honey))
        n.addChild(ellipse(center: CGPoint(x: 0, y: 98), size: CGSize(width: 7, height: 5), fill: brown))
        n.addChild(polyline([CGPoint(x: -8, y: 90), CGPoint(x: 0, y: 87),
                             CGPoint(x: 8, y: 90)], color: ink, width: 2))
        return n
    }

    // MARK: - Betty Boop

    private static func betty() -> SKNode {
        let n = SKNode()
        // Long legs
        n.addChild(polyline([CGPoint(x: -8, y: 42), CGPoint(x: -8, y: 12)], color: tan, width: 6))
        n.addChild(polyline([CGPoint(x: 8, y: 42), CGPoint(x: 8, y: 12)], color: tan, width: 6))
        // Heels
        n.addChild(ellipse(center: CGPoint(x: -10, y: 7), size: CGSize(width: 16, height: 10), fill: ink))
        n.addChild(ellipse(center: CGPoint(x: 10, y: 7), size: CGSize(width: 16, height: 10), fill: ink))
        // Red dress (flared triangle)
        n.addChild(polygon([CGPoint(x: -13, y: 82), CGPoint(x: 13, y: 82),
                            CGPoint(x: 22, y: 42), CGPoint(x: -22, y: 42)], fill: red))
        // Arms + gloves
        n.addChild(polyline([CGPoint(x: -11, y: 76), CGPoint(x: -24, y: 62)], color: tan, width: 5))
        n.addChild(polyline([CGPoint(x: 11, y: 76), CGPoint(x: 24, y: 62)], color: tan, width: 5))
        n.addChild(glove(at: CGPoint(x: -27, y: 60)))
        n.addChild(glove(at: CGPoint(x: 27, y: 60)))
        // Black bob hair (back layer)
        n.addChild(circle(center: CGPoint(x: 0, y: 100), radius: 23, fill: ink))
        // Hoop earrings
        n.addChild(circle(center: CGPoint(x: -22, y: 94), radius: 5, fill: .clear,
                          stroke: gold, lineWidth: 2))
        n.addChild(circle(center: CGPoint(x: 22, y: 94), radius: 5, fill: .clear,
                          stroke: gold, lineWidth: 2))
        // Face
        n.addChild(circle(center: CGPoint(x: 0, y: 98), radius: 15, fill: paper))
        // Bangs across forehead
        n.addChild(polygon([CGPoint(x: -15, y: 104), CGPoint(x: 15, y: 104),
                            CGPoint(x: 11, y: 113), CGPoint(x: -11, y: 113)], fill: ink))
        // Eyes with lashes
        n.addChild(circle(center: CGPoint(x: -6, y: 100), radius: 2.5, fill: ink))
        n.addChild(circle(center: CGPoint(x: 6, y: 100), radius: 2.5, fill: ink))
        n.addChild(polyline([CGPoint(x: -11, y: 102), CGPoint(x: -14, y: 104)], color: ink, width: 1.5))
        n.addChild(polyline([CGPoint(x: 11, y: 102), CGPoint(x: 14, y: 104)], color: ink, width: 1.5))
        // Red lips
        n.addChild(ellipse(center: CGPoint(x: 0, y: 90), size: CGSize(width: 8, height: 5), fill: red))
        return n
    }
}
