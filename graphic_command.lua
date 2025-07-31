-- ======================================================================
-- !!! 最重要方針：既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- graphic_command.lua : 画像読込と描画（定義は config/graphics_manifest.lua）
-- 追加/改良点：
--  ・背景タイル：画面の見え幅+1タイルを整数座標で敷く → 黒い継ぎ目防止（既存維持）
--  ・斜め移動は上下に統一（既存維持）
--  ・★ 歩行アニメ対応（移動中のみ再生／停止で中央フレームを表示）
--  ・★ 一枚絵(スプライトシート)対応：
--      manifest 側で
--        player.<variant>.sheet = {
--          path      = "assets/graphics/player/xxx.png",
--          frame_w   = 32,            -- 1コマの幅
--          frame_h   = 32,            -- 1コマの高さ
--          order     = {"down","left","right","up"}, -- 行の並び（row時）
--          layout    = "row",         -- "row"=方向が行、横にフレームが並ぶ（RPGツクール風）
--          frames    = 3,             -- 1方向あたりのコマ数（3推奨）
--          fps       = 8              -- 再生速度（省略時8）
--        }
--      ※ 既存の up/down/left/right 画像4枚方式もそのまま使えます（静止表示）。
-- ======================================================================

local G = {}

local manifest = nil

-- images.player[variant] の構造：
--  A) 4枚方式    : { type="separate", imgs={up=Image,down=Image,left=Image,right=Image} }
--  B) シート方式 : { type="sheet", img=Image, quads={dir={Quad,Quad,..}}, fw=, fh=, frames=, fps= }
local images = { background = {}, player = {} }

-- 内部状態：前フレーム位置→向き/移動推定 & アニメ
local last_x, last_y = nil, nil
local facing = "down" -- up/down/left/right
local moving = false
local anim_t = 0       -- 経過時間
local anim_idx = 1     -- 現在コマ（1開始）

local function _load_image(path)
  local ok, img = pcall(love.graphics.newImage, path)
  if not ok or not img then
    print(("[graphics] load failed: %s"):format(path))
    return nil
  end
  img:setFilter("nearest", "nearest") -- にじみ防止
  return img
end

local function _build_variant_from_separate(tbl)
  local v = { type="separate", imgs={} }
  v.imgs.up    = tbl.up    and _load_image(tbl.up)    or nil
  v.imgs.down  = tbl.down  and _load_image(tbl.down)  or nil
  v.imgs.left  = tbl.left  and _load_image(tbl.left)  or nil
  v.imgs.right = tbl.right and _load_image(tbl.right) or nil
  return v
end

local function _build_variant_from_sheet(sheet)
  -- sheet = { path, frame_w, frame_h, order, layout, frames, fps }
  local img = sheet.path and _load_image(sheet.path) or nil
  if not img then return nil end
  local fw = sheet.frame_w or 32
  local fh = sheet.frame_h or 32
  local order = sheet.order or {"down","left","right","up"}
  local layout = sheet.layout or "row"      -- RPGツクール風は "row"
  local frames = sheet.frames or 3          -- 1方向あたりのコマ数
  local fps    = sheet.fps or 8

  local iw, ih = img:getWidth(), img:getHeight()
  local quads_by_dir = {}

  if layout == "row" then
    -- 行：方向、列：アニメフレーム（0..frames-1）
    for row_idx, dir in ipairs(order) do
      local list = {}
      for f = 1, frames do
        local x = (f-1) * fw
        local y = (row_idx-1) * fh
        if x + fw <= iw and y + fh <= ih then
          table.insert(list, love.graphics.newQuad(x, y, fw, fh, iw, ih))
        end
      end
      quads_by_dir[dir] = list
    end
  else
    -- column レイアウト（列：方向、行：アニメフレーム）
    for col_idx, dir in ipairs(order) do
      local list = {}
      for f = 1, frames do
        local x = (col_idx-1) * fw
        local y = (f-1) * fh
        if x + fw <= iw and y + fh <= ih then
          table.insert(list, love.graphics.newQuad(x, y, fw, fh, iw, ih))
        end
      end
      quads_by_dir[dir] = list
    end
  end

  return { type="sheet", img=img, quads=quads_by_dir, fw=fw, fh=fh, frames=frames, fps=fps }
end

function G.init()
  local ok, mod = pcall(require, "config.graphics_manifest")
  manifest = ok and mod or { background = {}, player = {} }

  -- 背景
  for key, path in pairs(manifest.background or {}) do
    images.background[key] = _load_image(path)
  end

  -- プレイヤー（variant ごとに 4枚 or シート）
  images.player = {}
  for variant, tbl in pairs(manifest.player or {}) do
    if type(tbl) == "table" and (tbl.up or tbl.down or tbl.left or tbl.right) then
      images.player[variant] = _build_variant_from_separate(tbl)
    elseif type(tbl) == "table" and tbl.sheet then
      local v = _build_variant_from_sheet(tbl.sheet)
      if v then images.player[variant] = v end
    end
  end
end

G._player_variant = "standard"
function G.set_player_variant(id)
  G._player_variant = images.player[id] and id or "standard"
  -- アニメ初期化
  anim_t, anim_idx = 0, 1
end

-- 向き推定＆歩行アニメ更新（斜めは上下に統一）
function G.update(dt, player)
  if not player then return end
  local x, y = player.x or 0, player.y or 0
  if last_x and last_y then
    local dx, dy = x - last_x, y - last_y
    local ax, ay = math.abs(dx), math.abs(dy)
    local m = math.sqrt(dx*dx + dy*dy)
    moving = (m > 0.1)
    if moving then
      if ax > 0.1 and ay > 0.1 then
        facing = (dy > 0) and "down" or "up"  -- 斜め：縦
      elseif ax > ay then
        facing = (dx > 0) and "right" or "left"
      else
        facing = (dy > 0) and "down" or "up"
      end
    end
  end
  last_x, last_y = x, y

  -- アニメ進行（シート方式のみ／移動中のみ）
  local variant = images.player[G._player_variant or "standard"]
  if not variant or variant.type ~= "sheet" then return end
  local fps = variant.fps or 8
  if moving then
    anim_t = anim_t + dt
    if fps > 0 then
      anim_idx = (math.floor(anim_t * fps) % (variant.frames or 1)) + 1
    else
      anim_idx = 1
    end
  else
    -- 停止時は中央（例：3枚なら2枚目）
    local f = variant.frames or 1
    anim_idx = math.max(1, math.ceil(f/2))
    anim_t = 0
  end
end

-- 背景（切れ目無し）：画面サイズに応じて見える範囲+1タイルを敷く
function G.draw_background(player)
  local img = images.background["field_grass"]
  if not img then return end

  local iw, ih = img:getWidth(), img:getHeight()
  local px = (player and player.x) or 0
  local py = (player and player.y) or 0

  local sw, sh = love.graphics.getWidth(), love.graphics.getHeight()
  local left   = px - sw/2 - iw
  local right  = px + sw/2 + iw
  local top    = py - sh/2 - ih
  local bottom = py + sh/2 + ih

  local col_start = math.floor(left  / iw)
  local col_end   = math.floor(right / iw)
  local row_start = math.floor(top   / ih)
  local row_end   = math.floor(bottom/ ih)

  for cy = row_start, row_end do
    for cx = col_start, col_end do
      local x = cx * iw
      local y = cy * ih
      love.graphics.setColor(1,1,1,1)
      love.graphics.draw(img, math.floor(x+0.5), math.floor(y+0.5))
    end
  end
end

-- プレイヤー描画：シート優先→4枚→無ければ何もしない
function G.draw_player(player)
  if not player then return end
  local variant = images.player[G._player_variant or "standard"]
  if not variant then return end

  if variant.type == "sheet" then
    local list = variant.quads[facing] or {}
    local quad = list[anim_idx] or list[1]
    if not quad then return end
    local fw, fh = variant.fw, variant.fh
    local x = (player.x or 0) - math.floor(fw/2)
    local y = (player.y or 0) - math.floor(fh/2)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(variant.img, quad, math.floor(x+0.5), math.floor(y+0.5))
    return
  end

  if variant.type == "separate" then
    local set = variant.imgs
    local img = set[facing] or set.down or set.right or set.left or set.up
    if not img then return end
    local iw, ih = img:getWidth(), img:getHeight()
    local x = (player.x or 0) - math.floor(iw/2)
    local y = (player.y or 0) - math.floor(ih/2)
    love.graphics.setColor(1,1,1,1)
    love.graphics.draw(img, math.floor(x+0.5), math.floor(y+0.5))
    return
  end
end

return G




