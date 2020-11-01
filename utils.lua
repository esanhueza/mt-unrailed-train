function vector.angle_y(v1, v2)
  return vector.angle(v1, {x=v2.x, y=0, z=v2.z})
end

function table.find(t, l)
  for _, v in ipairs(t) do
    if l == v then
      return v
    end
  end
  return nil
end

function table.find_index(t, l)
  for i, v in ipairs(t) do
    if l == v then
      return i
    end
  end
  return nil
end

function table.last (t)
  local last = nil
  for _, k in pairs(t) do
      last = k
  end
  return last
end

function table.length (self)
  local i = 0
  for j, _ in pairs(self) do
      i = j
  end
  return i
end

function table.empty (self)
  for _, _ in pairs(self) do
      return false
  end
  return true
end