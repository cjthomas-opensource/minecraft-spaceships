execute if entity @e[type=rabbit,nbt={CustomName:'{"text":"SpaceBunny"}'}] run say Warp bunny is busy!
execute unless entity @e[type=rabbit,nbt={CustomName:'{"text":"SpaceBunny"}'}] run function cjt_ship:disc32/east48_real
