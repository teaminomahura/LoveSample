-- ======================================================================
-- !!! 既存のコードを修正箇所以外、一切変更・省略・削除しないで保持する !!!
-- music_command.lua : BGM/ME 管理（ファイル定義は config/audio_manifest.lua）
-- ・BGMはループ再生、MEはワンショット後に直前BGMへ復帰
-- ・ファイルが無い場合は無音で安全（printで警告）
-- ======================================================================

local M = {}

local manifest = nil
local bgm = { current_id = nil, src = nil }
local me  = { id = nil,   src = nil, was_bgm_id = nil }

local function _safe_new_source(path, type_)
  local ok, src = pcall(love.audio.newSource, path, type_ or "stream")
  if not ok then
    print(("[music] load failed: %s"):format(path))
    return nil
  end
  return src
end

function M.init()
  local ok, mod = pcall(require, "config.audio_manifest")
  manifest = ok and mod or { bgm = {}, me = {} }
end

function M.play_bgm(id, opts)
  opts = opts or {}
  if bgm.current_id == id then
    if bgm.src and not bgm.src:isPlaying() then bgm.src:play() end
    return
  end
  if bgm.src then bgm.src:stop(); bgm.src = nil end
  bgm.current_id = nil

  local path = manifest and manifest.bgm and manifest.bgm[id]
  if not path then
    print(("[music] bgm '%s' not found in manifest"):format(tostring(id)))
    return
  end

  local src = _safe_new_source(path, "stream")
  if not src then return end
  src:setLooping(true)
  src:setVolume(opts.volume or 1.0)
  src:play()
  bgm.current_id, bgm.src = id, src
end

function M.stop_bgm()
  if bgm.src then bgm.src:stop() end
  bgm.current_id, bgm.src = nil, nil
end

function M.play_me(id, opts)
  opts = opts or {}
  local path = manifest and manifest.me and manifest.me[id]
  if not path then
    print(("[music] me '%s' not found in manifest"):format(tostring(id)))
    return
  end
  if me.src then me.src:stop() end
  me.was_bgm_id = bgm.current_id
  if bgm.src then bgm.src:stop() end

  local src = _safe_new_source(path, "static")
  if not src then return end
  src:setLooping(false)
  src:setVolume(opts.volume or 1.0)
  src:play()
  me.id, me.src = id, src
end

function M.update(dt)
  if me.src and (not me.src:isPlaying()) then
    me.src = nil
    if me.was_bgm_id then
      local resume_id = me.was_bgm_id
      me.was_bgm_id = nil
      M.play_bgm(resume_id)
    end
  end
end

return M

