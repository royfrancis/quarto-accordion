-- Author: Roy Francis

-- Add html dependencies
local function addHTMLDeps()
  quarto.doc.add_html_dependency({
    name = 'accordion',
    stylesheets = {'accordion.css'}
  })
end

-- Check if empty or nil
local function isEmpty(s)
  return s == '' or s == nil
end

-- Display error message in document and log warning
local function accordionError(msg)
  local fullMsg = "Accordion shortcode: " .. msg
  quarto.log.warning(fullMsg)
  return pandoc.RawInline("html",
    "<div class=\"accordion-error\">" ..
    "<strong>Accordion Error:</strong> " .. msg .. "</div>")
end

-- Get a kwarg value as string, or empty string if not set
local function getKwarg(kwargs, key)
  if kwargs[key] ~= nil then
    return pandoc.utils.stringify(kwargs[key])
  end
  return ""
end

-- Validate label contains only letters, numbers, dashes and underscores
local function isValidLabel(label)
  return string.find(label, "^[%w%-_]+$") ~= nil
end

-- Generate a unique id suffix from header and body content
local function generateId(accordionId, headerContent, bodyContent, item)
  if item.id ~= nil then
    return "-" .. accordionId .. "-" .. pandoc.utils.stringify(item.id)
  end

  local id = nil
  if headerContent ~= nil and bodyContent ~= nil then
    local id_hc = string.gsub(string.lower(string.sub(headerContent, -10)), "[^%w]", "")
    local id_bc = string.gsub(string.lower(string.sub(bodyContent, -10)), "[^%w]", "")
    id = id_hc .. id_bc
  end

  if id == nil or id == "" then
    id = ""
    local charset = {}
    for c = 48, 57  do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
    for _ = 1, 10 do
      id = id .. charset[math.random(1, #charset)]
    end
  end

  return "-" .. accordionId .. "-" .. id
end

-- Look up accordion items from yaml metadata by label
local function getItemsFromMeta(meta, accordionId)
  local meta_accordion = meta["accordion"]
  if meta_accordion == nil then
    return nil, "'" .. accordionId .. "': No 'accordion' entry found in document yaml metadata."
  end

  for i = 1, #meta_accordion do
    if next(meta_accordion[i]) == accordionId then
      return meta_accordion[i][accordionId], nil
    end
  end

  return nil, "'" .. accordionId .. "': Accordion entry not found in yaml metadata."
end

-- Build accordion items from inline kwargs
local function getItemsFromKwargs(kwargs, accordionId)
  local header = getKwarg(kwargs, "header")
  local body = getKwarg(kwargs, "body")
  local items_json = getKwarg(kwargs, "items")

  if items_json ~= "" and (header ~= "" or body ~= "") then
    return nil, "'" .. accordionId .. "': Use either 'header'/'body' or 'items', not both."
  end

  if items_json ~= "" then
    local ok, items = pcall(quarto.json.decode, items_json)
    if not ok then
      return nil, "'" .. accordionId .. "': Failed to parse 'items' JSON string."
    end
    return items, nil
  end

  if header ~= "" or body ~= "" then
    if header == "" then
      return nil, "'" .. accordionId .. "': 'header' kwarg is missing."
    end
    if body == "" then
      return nil, "'" .. accordionId .. "': 'body' kwarg is missing."
    end
    local item = {header = header, body = body}
    local collapsed_val = getKwarg(kwargs, "collapsed")
    if collapsed_val == "false" then
      item.collapsed = false
    end
    local id_val = getKwarg(kwargs, "id")
    if id_val ~= "" then
      item.id = id_val
    end
    return {item}, nil
  end

  return nil, "'" .. accordionId .. "': 'label' kwarg specified without 'header'/'body' or 'items' kwargs."
end

-- Render accordion items to HTML
local function renderAccordion(accordionId, accordion_items, userLabel)
  local html = "<div id=\"" .. accordionId .. "\" class=\"accordion quarto-accordion\">\n"

  for i = 1, #accordion_items do
    local item = accordion_items[i]
    local headerContent = pandoc.utils.stringify(item.header or "")
    local bodyContent = pandoc.utils.stringify(item.body or "")

    if isEmpty(headerContent) or isEmpty(bodyContent) then
      local missing = {}
      if isEmpty(headerContent) then table.insert(missing, "header") end
      if isEmpty(bodyContent) then table.insert(missing, "body") end
      local missingStr = table.concat(missing, "' and '")
      local errorMsg = "'" .. userLabel .. "': Item " .. i .. " is missing '" .. missingStr .. "'."
      quarto.log.warning("Accordion shortcode: " .. errorMsg)
      html = html .. "<div class=\"accordion-error\"><strong>Accordion Error:</strong> " .. errorMsg .. "</div>\n"
    else
      local collapseId = generateId(accordionId, headerContent, bodyContent, item)
      local collapsed = item.collapsed
      if collapsed == nil then collapsed = true end

      local collapseClass = collapsed and "collapsed" or ""
      local collapseAria = collapsed and "false" or "true"
      local collapseShow = collapsed and "" or " show"

      html = html .. "<div class=\"accordion-item\">\n"
      html = html .. "<div class=\"accordion-header\" id=\"heading" .. collapseId .. "\">\n"
      html = html .. "<button class=\"accordion-button " .. collapseClass .. "\" type=\"button\" data-bs-toggle=\"collapse\" data-bs-target=\"#collapse" .. collapseId .. "\" aria-expanded=\"" .. collapseAria .. "\" aria-controls=\"collapse" .. collapseId .. "\">\n"
      html = html .. "<div class=\"accordion-header-content\"\n>"
      html = html .. headerContent
      html = html .. "</div>"
      html = html .. "</button>\n</div>\n"
      html = html .. "<div id=\"collapse" .. collapseId .. "\" class=\"accordion-collapse collapse" .. collapseShow .. "\" aria-labelledby=\"heading" .. collapseId .. "\" data-bs-parent=\"#" .. accordionId .. "\">\n"
      html = html .. "<div class=\"accordion-body\">\n"
      html = html .. "<div class=\"accordion-body-content\"\n>"
      html = html .. bodyContent
      html = html .. "</div>"
      html = html .. "</div>\n</div>\n</div>\n"
    end
  end

  html = html .. "</div>\n"
  return pandoc.RawInline("html", html)
end


-- Main Accordion Function Shortcode
return {

["accordion"] = function(args, kwargs, meta)
  
  if quarto.doc.is_format("html:js") then
    addHTMLDeps()

    local label = getKwarg(kwargs, "label")
    local hasLabel = label ~= ""
    local hasArgs = #args > 0

    -- Determine accordion id
    if hasLabel and hasArgs then
      return accordionError("Use either a positional argument or named arguments (label), not both.")
    elseif not hasLabel and not hasArgs then
      return accordionError("No arguments provided. Provide contents either as yaml metadata (positional argument) or inline (label kwarg).")
    end

    local accordionId = hasLabel and label or pandoc.utils.stringify(args[1])

    -- Validate label
    if not isValidLabel(accordionId) then
      return accordionError("'" .. accordionId .. "': Label contains invalid characters. Only letters, numbers, dashes (-) and underscores (_) are allowed.")
    end

    -- Get accordion items
    local accordion_items, err
    if hasLabel then
      accordion_items, err = getItemsFromKwargs(kwargs, accordionId)
    else
      accordion_items, err = getItemsFromMeta(meta, accordionId)
    end

    if err then return accordionError(err) end

    if accordion_items == nil or #accordion_items == 0 then
      return accordionError("'" .. accordionId .. "': Missing 'header' and 'body'.")
    end

    -- Prefix the accordion id for HTML
    local userLabel = accordionId
    accordionId = "quarto-accordion-" .. accordionId

    return renderAccordion(accordionId, accordion_items, userLabel)

  else
    print("Warning: Accordions are disabled because output format is not HTML.")
    return pandoc.Null()
  end

end
}
