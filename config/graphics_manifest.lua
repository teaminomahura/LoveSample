-- 最重要方針：既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- config/graphics_manifest.lua

local M = {}

-- 背景（前回と同じ）
M.background = {
  field_grass = "assets/graphics/background/field_grass.png",
}

-- プレイヤー：一枚絵（スプライトシート）方式
-- レイアウト：row（RPGツクール風）= 4行（down,left,right,up）× 3列（歩行3コマ）
M.player = {
  standard = {
    sheet = {
      path    = "assets/graphics/player/standard_sheet.png",
      frame_w = 32, frame_h = 32,
      order   = {"down","left","right","up"},
      layout  = "row",
      frames  = 3,
      fps     = 8,
    }
  },
  swift = {
    sheet = {
      path    = "assets/graphics/player/swift_sheet.png",
      frame_w = 32, frame_h = 32,
      order   = {"down","left","right","up"},
      layout  = "row",
      frames  = 3,
      fps     = 8,
    }
  }
}

return M



