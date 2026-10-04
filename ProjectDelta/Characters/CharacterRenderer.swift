import SceneKit
import UIKit

/// Code-drawn rubber-hose cartoon characters built from SceneKit primitives.
/// ~1.7 units tall, origin at feet. Unknown ids fall back to Willie.
enum CharacterRenderer {

    static func node(for id: String) -> SCNNode {
        switch id {
        case "felix": return felix()
        case "oswald": return oswald()
        case "popeye": return popeye()
        case "pooh": return pooh()
        case "betty": return betty()
        default: return willie()
        }
    }

    // MARK: - Part helpers

    private static func material(_ color: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.roughness = 0.7
        return m
    }

    private static func part(_ geometry: SCNGeometry, color: UIColor,
                             x: CGFloat, y: CGFloat, z: CGFloat) -> SCNNode {
        geometry.materials = [material(color)]
        let n = SCNNode(geometry: geometry)
        n.position = SCNVector3(x, y, z)
        return n
    }

    private static func sphere(_ r: CGFloat, _ color: UIColor,
                               _ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> SCNNode {
        part(SCNSphere(radius: r), color: color, x: x, y: y, z: z)
    }

    private static func box(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ color: UIColor,
                            _ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> SCNNode {
        part(SCNBox(width: w, height: h, length: d, chamferRadius: 0.02),
             color: color, x: x, y: y, z: z)
    }

    private static func cyl(_ r: CGFloat, _ h: CGFloat, _ color: UIColor,
                            _ x: CGFloat, _ y: CGFloat, _ z: CGFloat,
                            zTilt: CGFloat = 0, xTilt: CGFloat = 0) -> SCNNode {
        let n = part(SCNCylinder(radius: r, height: h), color: color, x: x, y: y, z: z)
        n.eulerAngles = SCNVector3(xTilt, 0, zTilt)
        return n
    }

    private static func cone(_ topR: CGFloat, _ botR: CGFloat, _ h: CGFloat, _ color: UIColor,
                             _ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> SCNNode {
        part(SCNCone(topRadius: topR, bottomRadius: botR, height: h),
             color: color, x: x, y: y, z: z)
    }

    private static func torus(_ ringR: CGFloat, _ pipeR: CGFloat, _ color: UIColor,
                              _ x: CGFloat, _ y: CGFloat, _ z: CGFloat) -> SCNNode {
        part(SCNTorus(ringRadius: ringR, pipeRadius: pipeR), color: color, x: x, y: y, z: z)
    }

    private static func assemble(_ parts: [SCNNode]) -> SCNNode {
        let root = SCNNode()
        for p in parts { root.addChildNode(p) }
        return root
    }

    // MARK: - Palette

    private static let black = UIColor.black
    private static let white = UIColor.white
    private static let red = UIColor(red: 0.85, green: 0.16, blue: 0.16, alpha: 1)
    private static let blue = UIColor(red: 0.20, green: 0.36, blue: 0.86, alpha: 1)
    private static let skin = UIColor(red: 0.98, green: 0.80, blue: 0.62, alpha: 1)
    private static let gold = UIColor(red: 0.95, green: 0.72, blue: 0.25, alpha: 1)
    private static let hoopGold = UIColor(red: 0.85, green: 0.64, blue: 0.20, alpha: 1)

    // MARK: - Steamboat Willie

    private static func willie() -> SCNNode {
        let muzzle = sphere(0.16, white, 0, 1.37, 0.20)
        muzzle.scale = SCNVector3(1.0, 0.72, 0.55)
        return assemble([
            cyl(0.07, 0.50, black, -0.12, 0.35, 0),
            cyl(0.07, 0.50, black,  0.12, 0.35, 0),
            box(0.24, 0.12, 0.36, black, -0.12, 0.06, 0.06),
            box(0.24, 0.12, 0.36, black,  0.12, 0.06, 0.06),
            cyl(0.23, 0.30, red, 0, 0.66, 0),
            cyl(0.17, 0.38, black, 0, 1.00, 0),
            cyl(0.055, 0.42, black, -0.30, 1.02, 0, zTilt: 0.5),
            cyl(0.055, 0.42, black,  0.30, 1.02, 0, zTilt: -0.5),
            sphere(0.11, white, -0.44, 0.86, 0),
            sphere(0.11, white,  0.44, 0.86, 0),
            sphere(0.30, black, 0, 1.44, 0),
            sphere(0.13, black, -0.22, 1.70, 0),
            sphere(0.13, black,  0.22, 1.70, 0),
            muzzle,
            sphere(0.085, white, -0.10, 1.52, 0.235),
            sphere(0.085, white,  0.10, 1.52, 0.235),
            sphere(0.032, black, -0.10, 1.52, 0.305),
            sphere(0.032, black,  0.10, 1.52, 0.305),
            sphere(0.055, black, 0, 1.43, 0.30),
        ])
    }

    // MARK: - Felix the Cat

    private static func felix() -> SCNNode {
        let grin = torus(0.13, 0.028, white, 0, 1.22, 0.20)
        grin.scale = SCNVector3(1.0, 0.5, 0.6)
        return assemble([
            cyl(0.08, 0.40, black, -0.11, 0.30, 0),
            cyl(0.08, 0.40, black,  0.11, 0.30, 0),
            sphere(0.22, black, 0, 0.75, 0),
            sphere(0.28, black, 0, 1.32, 0),
            cone(0.0, 0.10, 0.20, black, -0.16, 1.56, 0),
            cone(0.0, 0.10, 0.20, black,  0.16, 1.56, 0),
            sphere(0.11, white, -0.11, 1.40, 0.20),
            sphere(0.11, white,  0.11, 1.40, 0.20),
            sphere(0.04, black, -0.11, 1.40, 0.29),
            sphere(0.04, black,  0.11, 1.40, 0.29),
            grin,
            cyl(0.045, 0.55, black, 0, 0.85, -0.32, xTilt: 0.7),
        ])
    }

    // MARK: - Oswald the Lucky Rabbit

    private static func oswald() -> SCNNode {
        let muzzle = sphere(0.16, white, 0, 1.37, 0.20)
        muzzle.scale = SCNVector3(1.0, 0.72, 0.55)
        return assemble([
            cyl(0.07, 0.50, black, -0.12, 0.35, 0),
            cyl(0.07, 0.50, black,  0.12, 0.35, 0),
            box(0.24, 0.12, 0.36, black, -0.12, 0.06, 0.06),
            box(0.24, 0.12, 0.36, black,  0.12, 0.06, 0.06),
            cyl(0.23, 0.30, blue, 0, 0.66, 0),
            cyl(0.17, 0.38, black, 0, 1.00, 0),
            cyl(0.055, 0.42, black, -0.30, 1.02, 0, zTilt: 0.5),
            cyl(0.055, 0.42, black,  0.30, 1.02, 0, zTilt: -0.5),
            sphere(0.11, white, -0.44, 0.86, 0),
            sphere(0.11, white,  0.44, 0.86, 0),
            sphere(0.30, black, 0, 1.44, 0),
            cyl(0.065, 0.50, black, -0.20, 1.90, 0, zTilt: 0.28),
            cyl(0.065, 0.50, black,  0.20, 1.90, 0, zTilt: -0.28),
            sphere(0.065, black, -0.27, 2.13, 0),
            sphere(0.065, black,  0.27, 2.13, 0),
            muzzle,
            sphere(0.085, white, -0.10, 1.52, 0.235),
            sphere(0.085, white,  0.10, 1.52, 0.235),
            sphere(0.032, black, -0.10, 1.52, 0.305),
            sphere(0.032, black,  0.10, 1.52, 0.305),
        ])
    }

    // MARK: - Popeye the Sailor

    private static func popeye() -> SCNNode {
        assemble([
            cyl(0.07, 0.45, skin, -0.12, 0.32, 0),
            cyl(0.07, 0.45, skin,  0.12, 0.32, 0),
            box(0.22, 0.12, 0.34, black, -0.12, 0.06, 0.05),
            box(0.22, 0.12, 0.34, black,  0.12, 0.06, 0.05),
            cyl(0.20, 0.42, black, 0, 0.92, 0),
            cyl(0.06, 0.28, skin, -0.26, 1.02, 0, zTilt: 0.4),
            cyl(0.06, 0.28, skin,  0.26, 1.02, 0, zTilt: -0.4),
            cyl(0.13, 0.34, skin, -0.36, 0.80, 0),
            cyl(0.13, 0.34, skin,  0.36, 0.80, 0),
            sphere(0.26, skin, 0, 1.40, 0),
            cyl(0.20, 0.10, white, 0, 1.60, 0),
            box(0.14, 0.035, 0.03, black, 0.07, 1.45, 0.235),
            sphere(0.07, skin, 0, 1.38, 0.25),
        ])
    }

    // MARK: - Winnie the Pooh

    private static func pooh() -> SCNNode {
        assemble([
            sphere(0.275, black, 0, 1.24, -0.02), // outline shell behind head
            cyl(0.09, 0.35, gold, -0.13, 0.28, 0),
            cyl(0.09, 0.35, gold,  0.13, 0.28, 0),
            sphere(0.32, gold, 0, 0.72, 0),
            cyl(0.33, 0.30, red, 0, 0.78, 0),
            cyl(0.08, 0.32, gold, -0.34, 0.80, 0, zTilt: 0.35),
            cyl(0.08, 0.32, gold,  0.34, 0.80, 0, zTilt: -0.35),
            sphere(0.26, gold, 0, 1.24, 0),
            sphere(0.09, gold, -0.17, 1.44, 0),
            sphere(0.09, gold,  0.17, 1.44, 0),
            sphere(0.035, black, -0.09, 1.30, 0.225),
            sphere(0.035, black,  0.09, 1.30, 0.225),
            sphere(0.05, black, 0, 1.22, 0.245),
        ])
    }

    // MARK: - Betty Boop

    private static func betty() -> SCNNode {
        let lips = sphere(0.045, red, 0, 1.32, 0.225)
        lips.scale = SCNVector3(1.3, 0.6, 0.5)
        return assemble([
            cyl(0.07, 0.50, skin, -0.11, 0.35, 0),
            cyl(0.07, 0.50, skin,  0.11, 0.35, 0),
            box(0.16, 0.10, 0.28, black, -0.11, 0.05, 0.04),
            box(0.16, 0.10, 0.28, black,  0.11, 0.05, 0.04),
            cone(0.12, 0.32, 0.55, red, 0, 0.82, 0),
            cyl(0.055, 0.34, skin, -0.24, 1.05, 0, zTilt: 0.3),
            cyl(0.055, 0.34, skin,  0.24, 1.05, 0, zTilt: -0.3),
            sphere(0.25, black, 0, 1.40, -0.05),
            sphere(0.215, skin, 0, 1.40, 0.03),
            torus(0.05, 0.014, hoopGold, -0.225, 1.32, 0.06),
            torus(0.05, 0.014, hoopGold,  0.225, 1.32, 0.06),
            sphere(0.04, black, -0.08, 1.44, 0.215),
            sphere(0.04, black,  0.08, 1.44, 0.215),
            lips,
        ])
    }
}
