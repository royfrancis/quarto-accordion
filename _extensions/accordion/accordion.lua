-- Author: Roy Francis

-- Add html dependencies
local htmlDepsAdded = false
local function addHTMLDeps()
  if not htmlDepsAdded then
    quarto.doc.add_html_dependency({
      name = 'accordion',
      stylesheets = {'accordion.css'}
    })
    htmlDepsAdded = true
  end
end

-- Add revealjs dependencies (Bootstrap accordion CSS + collapse handler JS)
local revealjsDepsAdded = false
local function addRevealjsDeps()
  if not revealjsDepsAdded then
    quarto.doc.add_html_dependency({
      name = 'accordion',
      stylesheets = {'accordion.css'}
    })
    quarto.doc.add_html_dependency({
      name = 'accordion-revealjs',
      stylesheets = {'accordion-revealjs.css'},
      scripts = {'accordion-revealjs.js'}
    })
    revealjsDepsAdded = true
  end
end

-- Add LaTeX dependencies (tcolorbox for card-style boxes)
local latexDepsAdded = false
local function addLatexDeps()
  if not latexDepsAdded then
    quarto.doc.include_text("in-header",
      "\\usepackage{tcolorbox}\n" ..
      "\\usepackage{xcolor}\n\\definecolor{accordionerror}{HTML}{721c24}")
    latexDepsAdded = true
  end
end

-- Escape LaTeX special characters in a string
local function escapeLatex(s)
  -- Use placeholder for backslash to avoid double-escaping
  s = string.gsub(s, "\\", "\0BACKSLASH\0")
  s = string.gsub(s, "%%", "\\%%")
  s = string.gsub(s, "{",  "\\{")
  s = string.gsub(s, "}",  "\\}")
  s = string.gsub(s, "#",  "\\#")
  s = string.gsub(s, "&",  "\\&")
  s = string.gsub(s, "%$", "\\$")
  s = string.gsub(s, "_",  "\\_")
  s = string.gsub(s, "~",  "\\textasciitilde{}")
  s = string.gsub(s, "%^", "\\textasciicircum{}")
  s = string.gsub(s, "\0BACKSLASH\0", "\\textbackslash{}")
  return s
end

-- Escape Typst special characters in a string
local function escapeTypst(s)
  -- Backslash first to avoid double-escaping
  s = string.gsub(s, "\\", "\\\\")
  s = string.gsub(s, "%[", "\\[")
  s = string.gsub(s, "%]", "\\]")
  s = string.gsub(s, "_", "\\_")
  s = string.gsub(s, "%*", "\\*")
  s = string.gsub(s, "#", "\\#")
  s = string.gsub(s, "%$", "\\$")
  s = string.gsub(s, "@", "\\@")
  s = string.gsub(s, "<", "\\<")
  s = string.gsub(s, ">", "\\>")
  return s
end

-- Check if empty or nil
local function isEmpty(s)
  return s == '' or s == nil
end

-- Display error message in document and log warning
local function accordionError(msg, format)
  local fullMsg = "Accordion shortcode: " .. msg
  quarto.log.warning(fullMsg)
  if format == "html" then
    return pandoc.RawInline("html",
      "<div class=\"accordion-error\">" ..
      "<strong>Accordion Error:</strong> " .. msg .. "</div>")
  elseif format == "pdf" then
    return pandoc.RawInline("latex",
      "{\\color{accordionerror}\\textbf{Accordion Error:} " .. escapeLatex(msg) .. "}")
  elseif format == "typst" then
    return pandoc.RawInline("typst",
      "#text(fill: rgb(\"#721c24\"))[*Accordion Error:* " .. escapeTypst(msg) .. "]")
  else
    return pandoc.Strong({pandoc.Str("Accordion Error: " .. msg)})
  end
end

-- Strip one matching pair of surrounding quotes from a string value
local function stripSurroundingQuotes(s)
  if s == nil or #s < 2 then
    return s
  end

  local first = string.sub(s, 1, 1)
  local last = string.sub(s, -1)
  if (first == '"' and last == '"') or (first == "'" and last == "'") then
    return string.sub(s, 2, -2)
  end

  return s
end

-- Get a kwarg value as string, or empty string if not set
local function getKwarg(kwargs, key)
  if kwargs[key] ~= nil then
    return stripSurroundingQuotes(pandoc.utils.stringify(kwargs[key]))
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

-- Convert a content value to a list of Pandoc Blocks
local function contentToBlocks(value)
  if value == nil then
    return pandoc.Blocks({})
  end

  local valType = pandoc.utils.type(value)

  if valType == "Inlines" then
    return pandoc.Blocks({pandoc.Plain(value)})
  end

  if valType == "Blocks" then
    return pandoc.Blocks(value)
  end

  -- Plain string (e.g. from inline kwargs) - parse as markdown
  if type(value) == "string" then
    local doc = pandoc.read(value, "markdown")
    -- Convert single Para to Plain to avoid extra <p> margin
    if #doc.blocks == 1 and doc.blocks[1].t == "Para" then
      return pandoc.Blocks({pandoc.Plain(doc.blocks[1].content)})
    end
    return doc.blocks
  end

  return pandoc.Blocks({pandoc.Plain({pandoc.Str(pandoc.utils.stringify(value))})})
end

-- Make block content bold by wrapping inlines in Strong
local function makeBold(blocks)
  local result = pandoc.Blocks({})
  for _, block in ipairs(blocks) do
    if block.t == "Plain" then
      result:insert(pandoc.Plain({pandoc.Strong(block.content)}))
    elseif block.t == "Para" then
      result:insert(pandoc.Para({pandoc.Strong(block.content)}))
    else
      result:insert(block)
    end
  end
  return result
end

-- Look up accordion items from yaml metadata by label
local function getItemsFromMeta(meta, accordionId)
  local meta_accordion = meta["accordion"]
  if meta_accordion == nil then
    return nil, "'" .. accordionId .. "': No 'accordion' entry found in document yaml metadata."
  end

  for i = 1, #meta_accordion do
    if meta_accordion[i][accordionId] ~= nil then
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

-- Render accordion items as Pandoc Blocks
local function renderAccordion(accordionId, accordion_items, userLabel)
  local blocks = pandoc.Blocks({})

  blocks:insert(pandoc.RawBlock("html",
    "<div id=\"" .. accordionId .. "\" class=\"accordion quarto-accordion\">"))

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
      blocks:insert(pandoc.RawBlock("html",
        "<div class=\"accordion-error\"><strong>Accordion Error:</strong> " .. errorMsg .. "</div>"))
    else
      local collapseId = generateId(accordionId, headerContent, bodyContent, item)
      local collapsed = item.collapsed
      if collapsed == nil then collapsed = true end

      local collapseClass = collapsed and "collapsed" or ""
      local collapseAria = collapsed and "false" or "true"
      local collapseShow = collapsed and "" or " show"

      -- Open accordion item, header, button
      blocks:insert(pandoc.RawBlock("html",
        "<div class=\"accordion-item\">\n" ..
        "<div class=\"accordion-header\" id=\"heading" .. collapseId .. "\">\n" ..
        "<button class=\"accordion-button " .. collapseClass .. "\" type=\"button\" " ..
        "data-bs-toggle=\"collapse\" data-bs-target=\"#collapse" .. collapseId .. "\" " ..
        "aria-expanded=\"" .. collapseAria .. "\" aria-controls=\"collapse" .. collapseId .. "\">\n" ..
        "<div class=\"accordion-header-content\">"))

      -- Header as native Pandoc content
      blocks:extend(contentToBlocks(item.header))

      -- Close header, open body
      blocks:insert(pandoc.RawBlock("html",
        "</div>\n</button>\n</div>\n" ..
        "<div id=\"collapse" .. collapseId .. "\" class=\"accordion-collapse collapse" .. collapseShow .. "\" " ..
        "aria-labelledby=\"heading" .. collapseId .. "\" data-bs-parent=\"#" .. accordionId .. "\">\n" ..
        "<div class=\"accordion-body\">\n" ..
        "<div class=\"accordion-body-content\">"))

      -- Body as native Pandoc content
      blocks:extend(contentToBlocks(item.body))

      -- Close body and accordion item
      blocks:insert(pandoc.RawBlock("html",
        "</div>\n</div>\n</div>\n</div>"))
    end
  end

  blocks:insert(pandoc.RawBlock("html", "</div>"))
  return blocks
end

-- Render accordion items as LaTeX cards (for PDF output)
local function renderAccordionLatex(accordion_items, userLabel)
  local blocks = pandoc.Blocks({})

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
      blocks:insert(pandoc.RawBlock("latex",
        "{\\color{accordionerror}\\textbf{Accordion Error:} " .. escapeLatex(errorMsg) .. "}"))
    else
      -- Open tcolorbox
      blocks:insert(pandoc.RawBlock("latex",
        "\\begin{tcolorbox}[colback=white, colframe=black!20, " ..
        "boxrule=0.5pt, arc=3pt]"))

      -- Header (bold)
      blocks:extend(makeBold(contentToBlocks(item.header)))

      -- Separator between header and body
      blocks:insert(pandoc.RawBlock("latex", "\\tcblower"))

      -- Body
      blocks:extend(contentToBlocks(item.body))

      -- Close tcolorbox
      blocks:insert(pandoc.RawBlock("latex", "\\end{tcolorbox}"))
    end
  end

  return blocks
end

-- Render accordion items as Typst cards
local function renderAccordionTypst(accordion_items, userLabel)
  local blocks = pandoc.Blocks({})

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
      blocks:insert(pandoc.RawBlock("typst",
        "#text(fill: rgb(\"#721c24\"))[*Accordion Error:* " .. escapeTypst(errorMsg) .. "]"))
    else
      -- Open card with rounded border
      blocks:insert(pandoc.RawBlock("typst",
        "#block(width: 100%, stroke: 0.5pt + luma(180), radius: 4pt, inset: 0pt, below: 8pt, breakable: false)[\n" ..
        "#block(inset: 10pt, width: 100%, below: 0pt, above: 0pt)["))

      -- Header (bold)
      blocks:extend(makeBold(contentToBlocks(item.header)))

      -- Close header block, separator line, open body block
      blocks:insert(pandoc.RawBlock("typst",
        "]\n#line(length: 100%, stroke: 0.3pt + luma(200))\n" ..
        "#block(inset: 10pt, width: 100%, below: 0pt, above: 0pt)["))

      -- Body
      blocks:extend(contentToBlocks(item.body))

      -- Close body block and card
      blocks:insert(pandoc.RawBlock("typst", "]\n]"))
    end
  end

  return blocks
end


-- Render accordion items as native Pandoc blocks (fallback for unsupported formats)
local function renderAccordionFallback(accordion_items, userLabel)
  local blocks = pandoc.Blocks({})

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
      blocks:insert(pandoc.Para({pandoc.Strong({pandoc.Str("Accordion Error: " .. errorMsg)})}))
    else
      -- Header (bold)
      blocks:extend(makeBold(contentToBlocks(item.header)))
      -- Body
      blocks:extend(contentToBlocks(item.body))
    end

    -- Separator between items
    if i < #accordion_items then
      blocks:insert(pandoc.HorizontalRule())
    end
  end

  return blocks
end


-- Main Accordion Function Shortcode
return {

["accordion"] = function(args, kwargs, meta)

  -- Detect output format
  local format = nil
  if quarto.doc.is_format("revealjs") then
    format = "html"
    addRevealjsDeps()
  elseif quarto.doc.is_format("html:js") then
    format = "html"
    addHTMLDeps()
  elseif quarto.doc.is_format("pdf") then
    format = "pdf"
    addLatexDeps()
  elseif quarto.doc.is_format("typst") then
    format = "typst"
  else
    format = "fallback"
  end

  local label = getKwarg(kwargs, "label")
  local hasLabel = label ~= ""
  local hasArgs = #args > 0

  -- Determine accordion id
  if hasLabel and hasArgs then
    return accordionError("Use either a positional argument or named arguments (label), not both.", format)
  elseif not hasLabel and not hasArgs then
    return accordionError("No arguments provided. Provide contents either as yaml metadata (positional argument) or inline (label kwarg).", format)
  end

  local accordionId = hasLabel and label or pandoc.utils.stringify(args[1])

  -- Validate label
  if not isValidLabel(accordionId) then
    return accordionError("'" .. accordionId .. "': Label contains invalid characters. Only letters, numbers, dashes (-) and underscores (_) are allowed.", format)
  end

  -- Get accordion items
  local accordion_items, err
  if hasLabel then
    accordion_items, err = getItemsFromKwargs(kwargs, accordionId)
  else
    accordion_items, err = getItemsFromMeta(meta, accordionId)
  end

  if err then return accordionError(err, format) end

  if accordion_items == nil or #accordion_items == 0 then
    return accordionError("'" .. accordionId .. "': Missing 'header' and 'body'.", format)
  end

  local userLabel = accordionId
  accordionId = "quarto-accordion-" .. accordionId

  if format == "html" then
    return renderAccordion(accordionId, accordion_items, userLabel)
  elseif format == "pdf" then
    return renderAccordionLatex(accordion_items, userLabel)
  elseif format == "typst" then
    return renderAccordionTypst(accordion_items, userLabel)
  else
    return renderAccordionFallback(accordion_items, userLabel)
  end

end
}
