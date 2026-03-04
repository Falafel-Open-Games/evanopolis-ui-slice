class_name EconomyV0
extends RefCounted

const INITIAL_FIAT_BALANCE: float = 20.0
const INSPECTION_FEE: float = 10.0


static func base_property_price(city: String) -> float:
    if city == "caracas":
        return 3.0
    if city == "assuncion":
        return 4.0
    if city == "ciudad_del_este":
        return 5.0
    if city == "minsk":
        return 6.0
    if city == "irkutsk":
        return 7.0
    if city == "rockdale":
        return 8.0
    assert(false)
    return 0.0
