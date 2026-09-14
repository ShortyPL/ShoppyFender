extends RefCounted
class_name TestFunnyHuman


static func run() -> int:
	var failures := 0
	for kind: StringName in [&"regular", &"impatient", &"worker", &"cashier"]:
		var model := CharacterModel.new()
		model.set_kind(kind, 0)
		var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
		var ok := player != null and player.has_animation(&"Walk") and player.has_animation(&"Idle_Neutral")
		failures += _assert("%s has Walk and Idle_Neutral" % String(kind), ok)
		model.free()
	var hoodie := CharacterModel.new()
	hoodie.set_kind(&"regular", 0)
	var suit := CharacterModel.new()
	suit.set_kind(&"regular", 1)
	failures += _assert("regular outfits differ by variety", hoodie.look_id != suit.look_id)
	var head := hoodie.find_child("Casual_Head", true, false)
	var body := hoodie.find_child("Casual_Body", true, false)
	failures += _assert("customer uses a real character mesh", head != null and body != null)
	var basket := hoodie.find_child("Basket", true, false)
	var basket_item := hoodie.find_child("BasketItem", true, false) as MeshInstance3D
	failures += _assert("customer has empty basket", basket != null and basket_item != null and not basket_item.visible)
	hoodie.free()
	suit.free()
	var elder := CharacterModel.new()
	elder.set_kind(&"regular", 7)
	var bio := elder.find_child("Basket", true, false)
	failures += _assert("elder has grocery bag", bio != null)
	elder.free()
	var worker := CharacterModel.new()
	worker.set_kind(&"worker", 0)
	var carry := worker.find_child("Carry", true, false) as Node3D
	var vest := worker.find_child("Worker_Body", true, false)
	failures += _assert("worker carry starts hidden", carry != null and not carry.visible)
	failures += _assert("worker uses warehouse mesh", vest != null)
	worker.free()
	var cashier := CharacterModel.new()
	cashier.set_kind(&"cashier")
	var suit_body := cashier.find_child("Suit_Body", true, false)
	failures += _assert("cashier uses a suit mesh", suit_body != null)
	cashier.free()
	var shopper := CharacterModel.new()
	shopper.set_kind(&"regular")
	var product := ProductDefinition.new()
	product.id = &"freshpop_cola_500"
	product.preview_color = Color(0.2, 0.6, 0.9)
	product.package_type = &"bottle_small"
	shopper.set_basket_product(product)
	var filled := shopper.find_child("BasketItem", true, false) as MeshInstance3D
	failures += _assert("basket shows product after pick", filled != null and filled.visible)
	shopper.free()
	var worker_model := CharacterModel.new()
	worker_model.set_kind(&"worker")
	worker_model.set_carry_goods(product, 6)
	var crate := worker_model.find_child("Carry", true, false) as Node3D
	var pack0 := worker_model.find_child("Pack0", true, false) as MeshInstance3D
	failures += _assert("worker shows crate after pick", crate != null and crate.visible and pack0 != null and pack0.visible)
	worker_model.clear_carry_goods()
	failures += _assert("worker hides crate after deliver", crate != null and not crate.visible)
	worker_model.free()
	return failures


static func _assert(label: String, ok: bool) -> int:
	if ok:
		print("  PASS  %s" % label)
		return 0
	print("  FAIL  %s" % label)
	return 1
