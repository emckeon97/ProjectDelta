import SceneKit

/// Spinning gold coin pickup.
final class Coin: SCNNode {

    override init() {
        super.init()
        build()
    }

    required init?(coder: NSCoder) { nil }

    private func build() {
        let gold = SCNMaterial()
        gold.diffuse.contents = UIColor(red: 0.96, green: 0.76, blue: 0.26, alpha: 1)
        gold.metalness.contents = 0.6
        gold.roughness.contents = 0.35

        let torus = SCNTorus(ringRadius: 0.28, pipeRadius: 0.11)
        torus.materials = [gold]
        addChildNode(SCNNode(geometry: torus))

        let disc = SCNNode(geometry: SCNCylinder(radius: 0.2, height: 0.06))
        let light = SCNMaterial()
        light.diffuse.contents = UIColor(red: 1.0, green: 0.9, blue: 0.55, alpha: 1)
        light.metalness.contents = 0.6
        light.roughness.contents = 0.35
        disc.geometry?.materials = [light]
        disc.eulerAngles.x = Float.pi / 2
        addChildNode(disc)
    }

    /// Called every frame by the scene — spins the coin around its vertical axis.
    func spin(_ dt: TimeInterval) {
        rotation = SCNVector4(0, 1, 0, rotation.w + Float(dt) * 4)
    }
}
