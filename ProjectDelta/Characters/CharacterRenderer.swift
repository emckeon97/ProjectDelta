import SceneKit
import UIKit

/// High-quality code-drawn rubber-hose cartoon characters built from SceneKit
/// primitives. ~1.7 units tall, origin at feet. Unknown ids fall back to Willie.
///
/// Techniques: inverted-hull ink outlines (black duplicate mesh, cullMode .front)
/// on major parts; 48-segment spheres for heads/bodies; layered eyes
/// (white + pupil + highlight); matte cartoon materials.
enum CharacterRenderer {

    private static func legacyNode(for id: String) -> SCNNode {
        switch id {
        case "felix": return felix()
        case "oswald": return oswald()
        case "popeye": return popeye()
        case "pooh": return pooh()
        case "betty": return betty()
        case "pete": return pete()
        case "minnie": return minnie()
        case "olive": return olive()
        case "bosko": return bosko()
        case "koko": return koko()
        case "bimbo": return bimbo()
        default: return willie()
        }
    }

    /// Character node for gameplay: a billboarded 2D sprite when art exists
    /// (crisp unlit cartoon look, always faces the camera), falling back to
    /// the code-drawn 3D model otherwise. Container origin at feet, ~1.75 tall.
    static func node(for id: String) -> SCNNode {
        let container = SCNNode()
        let inner = spriteNode(for: id) ?? legacyNode(for: id)
        container.addChildNode(inner)
        return container
    }

    /// Billboarded sprite plane for a character, or nil when no art is bundled.
    private static func spriteNode(for id: String) -> SCNNode? {
        guard let img = UIImage(named: id) else { return nil }
        let height: CGFloat = 1.75
        let width = height * img.size.width / img.size.height
        let plane = SCNPlane(width: width, height: height)
        let mat = SCNMaterial()
        mat.diffuse.contents = img
        mat.lightingModel = .constant
        plane.materials = [mat]
        let node = SCNNode(geometry: plane)
        node.position.y = Float(height / 2)
        let billboard = SCNBillboardConstraint()
        billboard.freeAxes = .Y
        node.constraints = [billboard]
        node.castsShadow = false
        return node
    }

    /// Whether bundled 2D sprite art exists for a character id.
    static func hasSprite(for id: String) -> Bool {
        UIImage(named: id) != nil
    }

    // MARK: - Materials

    /// Matte cartoon material.
    private static func toon(_ color: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.roughness.contents = 0.85
        return m
    }

    /// Inverted-hull ink outline material: black, front faces culled.
    private static func ink() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = UIColor.black
        m.cullMode = .front
        m.roughness.contents = 0.9
        return m
    }

    /// Shiny gold (earrings only).
    private static func goldMetal() -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = hoopGold
        m.metalness.contents = 0.6
        m.roughness.contents = 0.35
        return m
    }

    // MARK: - Smooth geometry

    private static func ball(_ r: CGFloat, _ seg: Int = 48) -> SCNSphere {
        let s = SCNSphere(radius: r)
        s.segmentCount = seg
        return s
    }

    private static func tube(_ r: CGFloat, _ h: CGFloat) -> SCNCylinder {
        let c = SCNCylinder(radius: r, height: h)
        c.radialSegmentCount = 32
        c.heightSegmentCount = 4
        return c
    }

    private static func spike(_ topR: CGFloat, _ botR: CGFloat, _ h: CGFloat) -> SCNCone {
        let c = SCNCone(topRadius: topR, bottomRadius: botR, height: h)
        c.radialSegmentCount = 32
        return c
    }

    private static func ring(_ ringR: CGFloat, _ pipeR: CGFloat) -> SCNTorus {
        let t = SCNTorus(ringRadius: ringR, pipeRadius: pipeR)
        t.ringSegmentCount = 32
        t.pipeSegmentCount = 12
        return t
    }

    // MARK: - Part builders

    /// Major part with an inverted-hull ink outline sibling.
    @discardableResult
    private static func major(_ geo: SCNGeometry, _ color: UIColor,
                              at p: (CGFloat, CGFloat, CGFloat),
                              scale s: (CGFloat, CGFloat, CGFloat) = (1, 1, 1),
                              tilt t: (CGFloat, CGFloat, CGFloat) = (0, 0, 0),
                              in root: SCNNode, outline o: CGFloat = 1.05,
                              mat custom: SCNMaterial? = nil) -> SCNNode {
        let n = SCNNode(geometry: geo)
        n.geometry?.materials = [custom ?? toon(color)]
        n.position = SCNVector3(p.0, p.1, p.2)
        n.scale = SCNVector3(s.0, s.1, s.2)
        n.eulerAngles = SCNVector3(t.0, t.1, t.2)
        root.addChildNode(n)
        if let hullGeo = geo.copy() as? SCNGeometry {
            hullGeo.materials = [ink()]
            let hull = SCNNode(geometry: hullGeo)
            hull.position = n.position
            hull.eulerAngles = n.eulerAngles
            hull.scale = SCNVector3(s.0 * o, s.1 * o, s.2 * o)
            root.addChildNode(hull)
        }
        return n
    }

    /// Small detail part, no outline.
    @discardableResult
    private static func minor(_ geo: SCNGeometry, _ color: UIColor,
                              at p: (CGFloat, CGFloat, CGFloat),
                              scale s: (CGFloat, CGFloat, CGFloat) = (1, 1, 1),
                              tilt t: (CGFloat, CGFloat, CGFloat) = (0, 0, 0),
                              in root: SCNNode,
                              mat custom: SCNMaterial? = nil) -> SCNNode {
        let n = SCNNode(geometry: geo)
        n.geometry?.materials = [custom ?? toon(color)]
        n.position = SCNVector3(p.0, p.1, p.2)
        n.scale = SCNVector3(s.0, s.1, s.2)
        n.eulerAngles = SCNVector3(t.0, t.1, t.2)
        root.addChildNode(n)
        return n
    }

    /// Layered toon eye: white ball + pupil + highlight, facing +z.
    private static func eye(at x: CGFloat, _ y: CGFloat, _ z: CGFloat,
                            r: CGFloat, in root: SCNNode) {
        minor(ball(r), white, at: (x, y, z), in: root)
        minor(ball(r * 0.45, 24), black, at: (x, y, z + r * 0.72), in: root)
        minor(ball(r * 0.16, 12), white,
              at: (x + r * 0.14, y + r * 0.16, z + r * 0.86), in: root)
    }

    /// Cartoon smile: flattened torus ring with its top half sunk into the face.
    private static func smile(at x: CGFloat, _ y: CGFloat, _ z: CGFloat,
                              ringR: CGFloat, pipeR: CGFloat,
                              wide: CGFloat = 1.0, in root: SCNNode) {
        minor(ring(ringR, pipeR), black, at: (x, y, z),
              scale: (wide, 0.55, 0.6), in: root)
    }

    // MARK: - Palette

    private static let black = UIColor.black
    private static let white = UIColor.white
    private static let red = UIColor(red: 0.85, green: 0.16, blue: 0.16, alpha: 1)
    private static let blue = UIColor(red: 0.20, green: 0.36, blue: 0.86, alpha: 1)
    private static let skin = UIColor(red: 0.98, green: 0.80, blue: 0.62, alpha: 1)
    private static let tan = UIColor(red: 0.90, green: 0.68, blue: 0.42, alpha: 1)
    private static let gold = UIColor(red: 0.95, green: 0.72, blue: 0.25, alpha: 1)
    private static let hoopGold = UIColor(red: 0.85, green: 0.64, blue: 0.20, alpha: 1)
    private static let brown = UIColor(red: 0.45, green: 0.28, blue: 0.15, alpha: 1)
    private static let pink = UIColor(red: 0.98, green: 0.55, blue: 0.55, alpha: 1)
    private static let darkBrown = UIColor(red: 0.25, green: 0.15, blue: 0.10, alpha: 1)
    private static let wine = UIColor(red: 0.45, green: 0.08, blue: 0.12, alpha: 1)

    // MARK: - Steamboat Willie

    private static func willie() -> SCNNode {
        let root = SCNNode()
        // shoes + legs
        minor(SCNBox(width: 0.24, height: 0.12, length: 0.38, chamferRadius: 0.03),
              black, at: (-0.12, 0.06, 0.06), in: root)
        minor(SCNBox(width: 0.24, height: 0.12, length: 0.38, chamferRadius: 0.03),
              black, at: (0.12, 0.06, 0.06), in: root)
        minor(tube(0.07, 0.50), black, at: (-0.12, 0.35, 0), in: root)
        minor(tube(0.07, 0.50), black, at: (0.12, 0.35, 0), in: root)
        // red shorts + white buttons
        major(tube(0.23, 0.32), red, at: (0, 0.68, 0), in: root)
        minor(ball(0.035, 16), white, at: (-0.08, 0.72, 0.215), in: root)
        minor(ball(0.035, 16), white, at: (0.08, 0.72, 0.215), in: root)
        // oval body
        major(ball(0.20), black, at: (0, 1.02, 0), scale: (1, 1.2, 0.9), in: root)
        // long thin arms + white gloves with fingers
        minor(tube(0.055, 0.45), black, at: (-0.32, 0.98, 0), tilt: (0, 0, -0.35), in: root)
        minor(tube(0.055, 0.45), black, at: (0.32, 0.98, 0), tilt: (0, 0, 0.35), in: root)
        for sx in [-1.0, 1.0] as [CGFloat] {
            let gx = sx * 0.42
            major(ball(0.11, 32), white, at: (gx, 0.70, 0), in: root, outline: 1.08)
            minor(ball(0.032, 12), white, at: (gx - 0.05, 0.80, 0), in: root)
            minor(ball(0.032, 12), white, at: (gx, 0.82, 0), in: root)
            minor(ball(0.032, 12), white, at: (gx + 0.05, 0.80, 0), in: root)
        }
        // big round head + ears
        major(ball(0.30), black, at: (0, 1.44, 0), in: root)
        major(ball(0.13, 32), black, at: (-0.22, 1.70, 0), in: root)
        major(ball(0.13, 32), black, at: (0.22, 1.70, 0), in: root)
        // muzzle, layered eyes, nose, smile
        minor(ball(0.16, 32), white, at: (0, 1.37, 0.20), scale: (1, 0.72, 0.55), in: root)
        eye(at: -0.10, 1.52, 0.235, r: 0.085, in: root)
        eye(at: 0.10, 1.52, 0.235, r: 0.085, in: root)
        minor(ball(0.055, 24), black, at: (0, 1.43, 0.30), in: root)
        smile(at: 0, 1.32, 0.24, ringR: 0.10, pipeR: 0.022, in: root)
        return root
    }

    // MARK: - Felix the Cat

    private static func felix() -> SCNNode {
        let root = SCNNode()
        // feet + legs
        minor(ball(0.10, 24), black, at: (-0.11, 0.08, 0.04), in: root)
        minor(ball(0.10, 24), black, at: (0.11, 0.08, 0.04), in: root)
        minor(tube(0.08, 0.40), black, at: (-0.11, 0.30, 0), in: root)
        minor(tube(0.08, 0.40), black, at: (0.11, 0.30, 0), in: root)
        // sleek body + head
        major(ball(0.22), black, at: (0, 0.72, 0), scale: (1, 1.25, 0.95), in: root)
        major(ball(0.28), black, at: (0, 1.30, 0), in: root)
        // pointy ears
        major(spike(0.0, 0.10, 0.22), black, at: (-0.16, 1.54, 0), in: root, outline: 1.08)
        major(spike(0.0, 0.10, 0.22), black, at: (0.16, 1.54, 0), in: root, outline: 1.08)
        // huge eyes
        eye(at: -0.11, 1.38, 0.20, r: 0.11, in: root)
        eye(at: 0.11, 1.38, 0.20, r: 0.11, in: root)
        // wide grin with teeth
        minor(ball(0.10, 24), white, at: (0, 1.14, 0.19), scale: (1.2, 0.45, 0.4), in: root)
        smile(at: 0, 1.16, 0.21, ringR: 0.14, pipeR: 0.030, wide: 1.15, in: root)
        // long curved tail
        minor(tube(0.045, 0.30), black, at: (0, 0.95, -0.28), tilt: (0.5, 0, 0), in: root)
        minor(tube(0.045, 0.30), black, at: (0, 0.72, -0.47), tilt: (1.0, 0, 0), in: root)
        minor(tube(0.045, 0.30), black, at: (0, 0.52, -0.60), tilt: (1.35, 0, 0), in: root)
        minor(ball(0.05, 16), black, at: (0, 0.42, -0.68), in: root)
        return root
    }

    // MARK: - Oswald the Lucky Rabbit

    private static func oswald() -> SCNNode {
        let root = SCNNode()
        // shoes + legs
        minor(SCNBox(width: 0.24, height: 0.12, length: 0.38, chamferRadius: 0.03),
              black, at: (-0.12, 0.06, 0.06), in: root)
        minor(SCNBox(width: 0.24, height: 0.12, length: 0.38, chamferRadius: 0.03),
              black, at: (0.12, 0.06, 0.06), in: root)
        minor(tube(0.07, 0.50), black, at: (-0.12, 0.35, 0), in: root)
        minor(tube(0.07, 0.50), black, at: (0.12, 0.35, 0), in: root)
        // blue shorts + buttons
        major(tube(0.23, 0.32), blue, at: (0, 0.68, 0), in: root)
        minor(ball(0.035, 16), white, at: (-0.08, 0.72, 0.215), in: root)
        minor(ball(0.035, 16), white, at: (0.08, 0.72, 0.215), in: root)
        // oval body
        major(ball(0.20), black, at: (0, 1.02, 0), scale: (1, 1.2, 0.9), in: root)
        // arms + gloves
        minor(tube(0.055, 0.45), black, at: (-0.32, 0.98, 0), tilt: (0, 0, -0.35), in: root)
        minor(tube(0.055, 0.45), black, at: (0.32, 0.98, 0), tilt: (0, 0, 0.35), in: root)
        for sx in [-1.0, 1.0] as [CGFloat] {
            let gx = sx * 0.42
            major(ball(0.11, 32), white, at: (gx, 0.70, 0), in: root, outline: 1.08)
            minor(ball(0.032, 12), white, at: (gx - 0.05, 0.80, 0), in: root)
            minor(ball(0.032, 12), white, at: (gx, 0.82, 0), in: root)
            minor(ball(0.032, 12), white, at: (gx + 0.05, 0.80, 0), in: root)
        }
        // head
        major(ball(0.30), black, at: (0, 1.44, 0), in: root)
        // LONG rabbit ears
        major(tube(0.065, 0.50), black, at: (-0.20, 1.92, 0), tilt: (0, 0, 0.28), in: root)
        major(tube(0.065, 0.50), black, at: (0.20, 1.92, 0), tilt: (0, 0, -0.28), in: root)
        minor(ball(0.065, 24), black, at: (-0.27, 2.15, 0), in: root)
        minor(ball(0.065, 24), black, at: (0.27, 2.15, 0), in: root)
        // face
        minor(ball(0.16, 32), white, at: (0, 1.37, 0.20), scale: (1, 0.72, 0.55), in: root)
        eye(at: -0.10, 1.52, 0.235, r: 0.085, in: root)
        eye(at: 0.10, 1.52, 0.235, r: 0.085, in: root)
        minor(ball(0.055, 24), black, at: (0, 1.43, 0.30), in: root)
        smile(at: 0, 1.32, 0.24, ringR: 0.10, pipeR: 0.022, in: root)
        return root
    }

    // MARK: - Popeye the Sailor

    private static func popeye() -> SCNNode {
        let root = SCNNode()
        // shoes + legs
        minor(SCNBox(width: 0.22, height: 0.12, length: 0.34, chamferRadius: 0.03),
              black, at: (-0.12, 0.06, 0.05), in: root)
        minor(SCNBox(width: 0.22, height: 0.12, length: 0.34, chamferRadius: 0.03),
              black, at: (0.12, 0.06, 0.05), in: root)
        minor(tube(0.07, 0.45), skin, at: (-0.12, 0.32, 0), in: root)
        minor(tube(0.07, 0.45), skin, at: (0.12, 0.32, 0), in: root)
        // black sailor shirt
        major(tube(0.20, 0.42), black, at: (0, 0.90, 0), in: root)
        // upper arms + GIANT forearms + fists
        minor(tube(0.06, 0.28), skin, at: (-0.27, 1.02, 0), tilt: (0, 0, -0.4), in: root)
        minor(tube(0.06, 0.28), skin, at: (0.27, 1.02, 0), tilt: (0, 0, 0.4), in: root)
        major(tube(0.13, 0.34), skin, at: (-0.37, 0.78, 0), in: root)
        major(tube(0.13, 0.34), skin, at: (0.37, 0.78, 0), in: root)
        minor(ball(0.10, 24), skin, at: (-0.40, 0.56, 0), in: root)
        minor(ball(0.10, 24), skin, at: (0.40, 0.56, 0), in: root)
        // head + jutted chin
        major(ball(0.26), skin, at: (0, 1.38, 0), in: root)
        minor(ball(0.14, 24), skin, at: (0, 1.24, 0.12), scale: (1.1, 0.8, 0.9), in: root)
        // sailor cap
        minor(tube(0.20, 0.10), white, at: (0, 1.60, 0), in: root)
        minor(ball(0.03, 12), white, at: (0, 1.66, 0), in: root)
        // one open eye, one famous squint
        eye(at: -0.09, 1.44, 0.225, r: 0.05, in: root)
        minor(SCNBox(width: 0.14, height: 0.035, length: 0.03, chamferRadius: 0.005),
              black, at: (0.09, 1.44, 0.235), in: root)
        // big nose
        minor(ball(0.07, 24), skin, at: (0, 1.36, 0.25), in: root)
        // corncob pipe
        minor(tube(0.025, 0.18), brown, at: (0.14, 1.28, 0.22), tilt: (0.3, 0, -0.9), in: root)
        minor(tube(0.035, 0.06), brown, at: (0.21, 1.24, 0.26), in: root)
        return root
    }

    // MARK: - Winnie the Pooh

    private static func pooh() -> SCNNode {
        let root = SCNNode()
        // feet + legs
        minor(ball(0.11, 24), gold, at: (-0.13, 0.09, 0.05), in: root)
        minor(ball(0.11, 24), gold, at: (0.13, 0.09, 0.05), in: root)
        minor(tube(0.09, 0.35), gold, at: (-0.13, 0.30, 0), in: root)
        minor(tube(0.09, 0.35), gold, at: (0.13, 0.30, 0), in: root)
        // plump body + red shirt
        major(ball(0.32), gold, at: (0, 0.70, 0), in: root)
        major(tube(0.335, 0.30), red, at: (0, 0.80, 0), in: root)
        // arms + paws
        minor(tube(0.08, 0.32), gold, at: (-0.35, 0.80, 0), tilt: (0, 0, -0.35), in: root)
        minor(tube(0.08, 0.32), gold, at: (0.35, 0.80, 0), tilt: (0, 0, 0.35), in: root)
        minor(ball(0.09, 24), gold, at: (-0.41, 0.63, 0), in: root)
        minor(ball(0.09, 24), gold, at: (0.41, 0.63, 0), in: root)
        // head + ears
        major(ball(0.26), gold, at: (0, 1.24, 0), in: root)
        minor(ball(0.09, 24), gold, at: (-0.17, 1.44, 0), in: root)
        minor(ball(0.09, 24), gold, at: (0.17, 1.44, 0), in: root)
        // snout, dot eyes, nose, smile
        minor(ball(0.12, 24), tan, at: (0, 1.18, 0.20), scale: (1, 0.8, 0.7), in: root)
        minor(ball(0.035, 12), black, at: (-0.09, 1.30, 0.225), in: root)
        minor(ball(0.035, 12), black, at: (0.09, 1.30, 0.225), in: root)
        minor(ball(0.05, 16), darkBrown, at: (0, 1.22, 0.26), in: root)
        smile(at: 0, 1.14, 0.22, ringR: 0.07, pipeR: 0.018, in: root)
        return root
    }

    // MARK: - Betty Boop

    private static func betty() -> SCNNode {
        let root = SCNNode()
        // shoes + long legs
        minor(SCNBox(width: 0.16, height: 0.10, length: 0.28, chamferRadius: 0.03),
              black, at: (-0.11, 0.05, 0.04), in: root)
        minor(SCNBox(width: 0.16, height: 0.10, length: 0.28, chamferRadius: 0.03),
              black, at: (0.11, 0.05, 0.04), in: root)
        minor(tube(0.07, 0.50), skin, at: (-0.11, 0.35, 0), in: root)
        minor(tube(0.07, 0.50), skin, at: (0.11, 0.35, 0), in: root)
        // red dress
        major(spike(0.13, 0.32, 0.55), red, at: (0, 0.80, 0), in: root)
        // arms + hands
        minor(tube(0.055, 0.34), skin, at: (-0.25, 1.02, 0), tilt: (0, 0, -0.3), in: root)
        minor(tube(0.055, 0.34), skin, at: (0.25, 1.02, 0), tilt: (0, 0, 0.3), in: root)
        minor(ball(0.06, 16), skin, at: (-0.30, 0.85, 0), in: root)
        minor(ball(0.06, 16), skin, at: (0.30, 0.85, 0), in: root)
        // black bob haircut behind the face
        major(ball(0.25), black, at: (0, 1.40, -0.05), in: root)
        minor(ball(0.215, 32), skin, at: (0, 1.40, 0.03), in: root)
        // gold hoop earrings (shiny)
        minor(ring(0.05, 0.014), hoopGold, at: (-0.225, 1.32, 0.06), in: root, mat: goldMetal())
        minor(ring(0.05, 0.014), hoopGold, at: (0.225, 1.32, 0.06), in: root, mat: goldMetal())
        // layered eyes + lashes
        eye(at: -0.08, 1.44, 0.215, r: 0.04, in: root)
        eye(at: 0.08, 1.44, 0.215, r: 0.04, in: root)
        minor(SCNBox(width: 0.05, height: 0.015, length: 0.02, chamferRadius: 0.004),
              black, at: (-0.08, 1.49, 0.21), tilt: (0, 0, 0.3), in: root)
        minor(SCNBox(width: 0.05, height: 0.015, length: 0.02, chamferRadius: 0.004),
              black, at: (0.08, 1.49, 0.21), tilt: (0, 0, -0.3), in: root)
        // blush, red lips, beauty mark
        minor(ball(0.03, 12), pink, at: (-0.13, 1.36, 0.20), scale: (1, 0.7, 0.5), in: root)
        minor(ball(0.03, 12), pink, at: (0.13, 1.36, 0.20), scale: (1, 0.7, 0.5), in: root)
        minor(ball(0.045, 16), red, at: (0, 1.32, 0.225), scale: (1.3, 0.6, 0.5), in: root)
        minor(ball(0.012, 8), black, at: (0.10, 1.30, 0.22), in: root)
        return root
    }

    // MARK: - Peg-Leg Pete

    private static func pete() -> SCNNode {
        let root = SCNNode()
        // wooden peg leg (right) + normal leg + shoe (left)
        minor(tube(0.06, 0.50), brown, at: (0.14, 0.25, 0), in: root)
        minor(ball(0.07, 16), darkBrown, at: (0.14, 0.04, 0), in: root)
        minor(tube(0.08, 0.50), black, at: (-0.14, 0.35, 0), in: root)
        minor(SCNBox(width: 0.26, height: 0.13, length: 0.40, chamferRadius: 0.03),
              black, at: (-0.14, 0.065, 0.06), in: root)
        // big burly belly
        major(ball(0.34), black, at: (0, 0.85, 0), scale: (1.15, 1.0, 1.0), in: root)
        // thick arms + heavy fists
        minor(tube(0.09, 0.42), black, at: (-0.44, 0.95, 0), tilt: (0, 0, -0.4), in: root)
        minor(tube(0.09, 0.42), black, at: (0.44, 0.95, 0), tilt: (0, 0, 0.4), in: root)
        minor(ball(0.12, 24), black, at: (-0.53, 0.72, 0), in: root)
        minor(ball(0.12, 24), black, at: (0.53, 0.72, 0), in: root)
        // head
        major(ball(0.30), black, at: (0, 1.50, 0), in: root)
        // captain's hat: brim + crown
        minor(tube(0.30, 0.05), white, at: (0, 1.74, 0), in: root)
        major(tube(0.21, 0.16), white, at: (0, 1.83, 0), in: root, outline: 1.06)
        // heavy brow + eyes beneath
        minor(SCNBox(width: 0.34, height: 0.07, length: 0.10, chamferRadius: 0.02),
              black, at: (0, 1.58, 0.24), in: root)
        eye(at: -0.10, 1.50, 0.245, r: 0.06, in: root)
        eye(at: 0.10, 1.50, 0.245, r: 0.06, in: root)
        // snout + nose
        minor(ball(0.15, 24), black, at: (0, 1.40, 0.22), scale: (1, 0.7, 0.6), in: root)
        minor(ball(0.06, 16), darkBrown, at: (0, 1.44, 0.30), in: root)
        // menacing grin + gold tooth
        smile(at: 0, 1.30, 0.24, ringR: 0.13, pipeR: 0.028, wide: 1.2, in: root)
        minor(SCNBox(width: 0.05, height: 0.06, length: 0.03, chamferRadius: 0.008),
              gold, at: (0.08, 1.28, 0.26), in: root)
        return root
    }

    // MARK: - Minnie Mouse

    private static func minnie() -> SCNNode {
        let root = SCNNode()
        // legs + heeled shoes
        minor(tube(0.06, 0.42), black, at: (-0.11, 0.30, 0), in: root)
        minor(tube(0.06, 0.42), black, at: (0.11, 0.30, 0), in: root)
        minor(SCNBox(width: 0.20, height: 0.10, length: 0.36, chamferRadius: 0.03),
              black, at: (-0.11, 0.05, 0.06), in: root)
        minor(SCNBox(width: 0.20, height: 0.10, length: 0.36, chamferRadius: 0.03),
              black, at: (0.11, 0.05, 0.06), in: root)
        // polka-dot skirt
        major(spike(0.16, 0.34, 0.42), red, at: (0, 0.62, 0), in: root)
        for a in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 4) {
            let dx = CGFloat(cos(a)) * 0.27
            let dz = CGFloat(sin(a)) * 0.27
            minor(ball(0.035, 12), white, at: (dx, 0.58, dz), in: root)
        }
        // body
        major(ball(0.19), black, at: (0, 0.98, 0), scale: (1, 1.15, 0.9), in: root)
        // arms + gloves
        minor(tube(0.05, 0.40), black, at: (-0.29, 0.95, 0), tilt: (0, 0, -0.35), in: root)
        minor(tube(0.05, 0.40), black, at: (0.29, 0.95, 0), tilt: (0, 0, 0.35), in: root)
        for sx in [-1.0, 1.0] as [CGFloat] {
            major(ball(0.10, 32), white, at: (sx * 0.38, 0.70, 0), in: root, outline: 1.08)
        }
        // head + round ears
        major(ball(0.28), black, at: (0, 1.38, 0), in: root)
        major(ball(0.12, 32), black, at: (-0.20, 1.62, 0), in: root)
        major(ball(0.12, 32), black, at: (0.20, 1.62, 0), in: root)
        // big bow
        minor(ball(0.11, 24), red, at: (-0.10, 1.78, 0), scale: (1, 0.7, 0.5), tilt: (0, 0, 0.4), in: root)
        minor(ball(0.11, 24), red, at: (0.10, 1.78, 0), scale: (1, 0.7, 0.5), tilt: (0, 0, -0.4), in: root)
        minor(ball(0.06, 16), red, at: (0, 1.76, 0.02), in: root)
        // face
        minor(ball(0.15, 32), white, at: (0, 1.31, 0.19), scale: (1, 0.72, 0.55), in: root)
        eye(at: -0.09, 1.46, 0.225, r: 0.075, in: root)
        eye(at: 0.09, 1.46, 0.225, r: 0.075, in: root)
        // eyelashes
        minor(SCNBox(width: 0.045, height: 0.014, length: 0.02, chamferRadius: 0.004),
              black, at: (-0.09, 1.51, 0.215), tilt: (0, 0, 0.35), in: root)
        minor(SCNBox(width: 0.045, height: 0.014, length: 0.02, chamferRadius: 0.004),
              black, at: (0.09, 1.51, 0.215), tilt: (0, 0, -0.35), in: root)
        minor(ball(0.05, 24), black, at: (0, 1.37, 0.28), in: root)
        smile(at: 0, 1.26, 0.23, ringR: 0.09, pipeR: 0.020, in: root)
        return root
    }

    // MARK: - Olive Oyl

    private static func olive() -> SCNNode {
        let root = SCNNode()
        // huge flat feet + very long thin legs
        minor(SCNBox(width: 0.16, height: 0.08, length: 0.42, chamferRadius: 0.03),
              black, at: (-0.10, 0.04, 0.10), in: root)
        minor(SCNBox(width: 0.16, height: 0.08, length: 0.42, chamferRadius: 0.03),
              black, at: (0.10, 0.04, 0.10), in: root)
        minor(tube(0.05, 0.70), skin, at: (-0.10, 0.43, 0), in: root)
        minor(tube(0.05, 0.70), skin, at: (0.10, 0.43, 0), in: root)
        // long dark dress
        major(spike(0.14, 0.30, 0.75), wine, at: (0, 1.05, 0), in: root)
        // skinny arms + hands
        minor(tube(0.045, 0.55), skin, at: (-0.24, 1.25, 0), tilt: (0, 0, -0.25), in: root)
        minor(tube(0.045, 0.55), skin, at: (0.24, 1.25, 0), tilt: (0, 0, 0.25), in: root)
        minor(ball(0.06, 16), skin, at: (-0.31, 0.97, 0), in: root)
        minor(ball(0.06, 16), skin, at: (0.31, 0.97, 0), in: root)
        // small head + black bob
        major(ball(0.22), black, at: (0, 1.68, -0.03), in: root)
        minor(ball(0.185, 32), skin, at: (0, 1.68, 0.02), in: root)
        // dot eyes, long nose, small smile
        minor(ball(0.030, 12), black, at: (-0.07, 1.72, 0.185), in: root)
        minor(ball(0.030, 12), black, at: (0.07, 1.72, 0.185), in: root)
        minor(ball(0.045, 16), skin, at: (0, 1.66, 0.20), scale: (0.8, 1.1, 0.8), in: root)
        smile(at: 0, 1.60, 0.19, ringR: 0.06, pipeR: 0.016, in: root)
        return root
    }

    // MARK: - Bosko

    private static func bosko() -> SCNNode {
        let root = SCNNode()
        // shoes + stubby legs
        minor(ball(0.11, 24), black, at: (-0.12, 0.09, 0.04), in: root)
        minor(ball(0.11, 24), black, at: (0.12, 0.09, 0.04), in: root)
        minor(tube(0.08, 0.34), black, at: (-0.12, 0.30, 0), in: root)
        minor(tube(0.08, 0.34), black, at: (0.12, 0.30, 0), in: root)
        // round ink-black body
        major(ball(0.26), black, at: (0, 0.72, 0), in: root)
        // arms + white gloves
        minor(tube(0.06, 0.34), black, at: (-0.32, 0.78, 0), tilt: (0, 0, -0.4), in: root)
        minor(tube(0.06, 0.34), black, at: (0.32, 0.78, 0), tilt: (0, 0, 0.4), in: root)
        minor(ball(0.09, 24), white, at: (-0.40, 0.60, 0), in: root)
        minor(ball(0.09, 24), white, at: (0.40, 0.60, 0), in: root)
        // big round head
        major(ball(0.30), black, at: (0, 1.32, 0), in: root)
        // derby hat
        minor(tube(0.32, 0.04), black, at: (0, 1.56, 0), in: root)
        major(tube(0.19, 0.16), black, at: (0, 1.65, 0), in: root, outline: 1.06)
        // pie eyes + big grin
        eye(at: -0.10, 1.38, 0.24, r: 0.085, in: root)
        eye(at: 0.10, 1.38, 0.24, r: 0.085, in: root)
        smile(at: 0, 1.20, 0.25, ringR: 0.13, pipeR: 0.028, wide: 1.2, in: root)
        return root
    }

    // MARK: - Koko the Clown

    private static func koko() -> SCNNode {
        let root = SCNNode()
        // shoes + legs (black suit)
        minor(ball(0.10, 24), black, at: (-0.11, 0.08, 0.04), in: root)
        minor(ball(0.10, 24), black, at: (0.11, 0.08, 0.04), in: root)
        minor(tube(0.07, 0.42), black, at: (-0.11, 0.32, 0), in: root)
        minor(tube(0.07, 0.42), black, at: (0.11, 0.32, 0), in: root)
        // black body suit + white pom-pom buttons
        major(ball(0.22), black, at: (0, 0.78, 0), scale: (1, 1.2, 0.9), in: root)
        minor(ball(0.045, 16), white, at: (0, 0.92, 0.20), in: root)
        minor(ball(0.045, 16), white, at: (0, 0.78, 0.21), in: root)
        minor(ball(0.045, 16), white, at: (0, 0.64, 0.20), in: root)
        // arms + white gloves
        minor(tube(0.055, 0.36), black, at: (-0.30, 0.82, 0), tilt: (0, 0, -0.35), in: root)
        minor(tube(0.055, 0.36), black, at: (0.30, 0.82, 0), tilt: (0, 0, 0.35), in: root)
        minor(ball(0.09, 24), white, at: (-0.38, 0.63, 0), in: root)
        minor(ball(0.09, 24), white, at: (0.38, 0.63, 0), in: root)
        // white clown face
        major(ball(0.27), white, at: (0, 1.34, 0), in: root)
        // pointed clown hat + pom
        major(spike(0.0, 0.20, 0.42), black, at: (0, 1.72, 0), tilt: (0, 0, 0.12), in: root)
        minor(ball(0.05, 16), white, at: (0.05, 1.93, 0), in: root)
        // red nose, pie eyes, big grin
        minor(ball(0.07, 20), red, at: (0, 1.32, 0.26), in: root)
        eye(at: -0.10, 1.44, 0.21, r: 0.07, in: root)
        eye(at: 0.10, 1.44, 0.21, r: 0.07, in: root)
        smile(at: 0, 1.22, 0.23, ringR: 0.12, pipeR: 0.026, wide: 1.25, in: root)
        return root
    }

    // MARK: - Bimbo

    private static func bimbo() -> SCNNode {
        let root = SCNNode()
        // paws + legs
        minor(ball(0.10, 24), white, at: (-0.12, 0.08, 0.04), in: root)
        minor(ball(0.10, 24), white, at: (0.12, 0.08, 0.04), in: root)
        minor(tube(0.075, 0.38), white, at: (-0.12, 0.30, 0), in: root)
        minor(tube(0.075, 0.38), white, at: (0.12, 0.30, 0), in: root)
        // white body with black spots
        major(ball(0.23), white, at: (0, 0.72, 0), scale: (1, 1.2, 0.95), in: root)
        minor(ball(0.09, 16), black, at: (0.12, 0.80, 0.16), scale: (1, 1, 0.5), in: root)
        minor(ball(0.07, 16), black, at: (-0.10, 0.60, 0.18), scale: (1, 1, 0.5), in: root)
        // arms + paws
        minor(tube(0.06, 0.34), white, at: (-0.31, 0.76, 0), tilt: (0, 0, -0.35), in: root)
        minor(tube(0.06, 0.34), white, at: (0.31, 0.76, 0), tilt: (0, 0, 0.35), in: root)
        minor(ball(0.085, 20), white, at: (-0.39, 0.58, 0), in: root)
        minor(ball(0.085, 20), white, at: (0.39, 0.58, 0), in: root)
        // white face
        major(ball(0.27), white, at: (0, 1.32, 0), in: root)
        // long floppy black ears
        major(tube(0.07, 0.42), black, at: (-0.24, 1.52, 0), tilt: (0, 0, 0.35), in: root)
        major(tube(0.07, 0.42), black, at: (0.24, 1.52, 0), tilt: (0, 0, -0.35), in: root)
        minor(ball(0.07, 20), black, at: (-0.31, 1.32, 0), in: root)
        minor(ball(0.07, 20), black, at: (0.31, 1.32, 0), in: root)
        // black patch over one eye
        minor(ball(0.10, 20), black, at: (-0.11, 1.40, 0.19), scale: (1, 1, 0.6), in: root)
        // pie eyes, black nose, grin
        eye(at: -0.10, 1.40, 0.225, r: 0.075, in: root)
        eye(at: 0.10, 1.40, 0.225, r: 0.075, in: root)
        minor(ball(0.06, 20), black, at: (0, 1.32, 0.26), in: root)
        smile(at: 0, 1.24, 0.24, ringR: 0.10, pipeR: 0.022, wide: 1.1, in: root)
        // tail
        minor(tube(0.04, 0.25), white, at: (0, 0.85, -0.28), tilt: (0.6, 0, 0), in: root)
        return root
    }
}
