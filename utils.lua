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

function table.last (self)
  local last = nil
  for _, k in pairs(self) do
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