execute if entity @e[type=marker,nbt={CustomName:'"SpaceBunnyEntity"'}] run say Warp Bunny is busy!
execute unless entity @e[type=marker,nbt={CustomName:'"SpaceBunnyEntity"'}] run function cjt_ship:disc32/south64_real
