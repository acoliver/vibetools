-- Give borderless Markdown tables explicit column widths so LaTeX wraps cells.
function Table(tbl)
  local count = #tbl.colspecs
  if count == 0 then
    return tbl
  end
  local width = 0.96 / count
  for _, spec in ipairs(tbl.colspecs) do
    spec[2] = width
  end
  return tbl
end
