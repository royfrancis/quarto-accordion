function Meta(meta)
  meta['quarto_version'] = tostring(quarto.version)
  meta['current_year'] = os.date("%Y")
  meta['current_date'] = os.date("%d-%m-%Y")
  meta['current_time'] = os.date("%H:%M:%S")
  return meta
end
