# Test
Roy Francis
15-Mar-2026

# Error tests

These tests should each produce an error message.

## No arguments

Expected error: No arguments provided.

``` lua
{{< accordion >}}
```

**Accordion Error: No arguments provided. Provide contents either as yaml metadata (positional argument) or inline (label kwarg).**

## Both positional and label kwargs

Expected error: Use either a positional argument or named arguments
(label), not both.

``` lua
{{< accordion yaml-simple label="mixed" header="This is a header" body="This is body content" >}}
```

**Accordion Error: Use either a positional argument or named arguments (label), not both.**

## Invalid label - space

Expected error: Label contains invalid characters.

``` lua
{{< accordion label="inline simple" header="Header" body="Body" >}}
```

**Accordion Error: 'inline simple': Label contains invalid characters. Only letters, numbers, dashes (-) and underscores (\_) are allowed.**

## Invalid label - special characters

Expected error: Label contains invalid characters.

``` lua
{{< accordion label="inline?simple" header="Header" body="Body" >}}
```

**Accordion Error: 'inline?simple': Label contains invalid characters. Only letters, numbers, dashes (-) and underscores (\_) are allowed.**

## YAML label not found in metadata

Expected error: Accordion entry not found in yaml metadata.

``` lua
{{< accordion nonexistent >}}
```

**Accordion Error: 'nonexistent': Accordion entry not found in yaml metadata.**

## YAML empty metadata for label

Expected error: Missing ‘header’ and ‘body’.

``` lua
{{< accordion yaml-empty >}}
```

**Accordion Error: 'yaml-empty': Missing 'header' and 'body'.**

## YAML item missing header

Expected error: Item 1 is missing ‘header’.

``` lua
{{< accordion yaml-missing-header >}}
```

**Accordion Error: 'yaml-missing-header': Item 1 is missing 'header'.**

## YAML item missing body

Expected error: Item 1 is missing ‘body’.

``` lua
{{< accordion yaml-missing-body >}}
```

**Accordion Error: 'yaml-missing-body': Item 1 is missing 'body'.**

## YAML item missing both header and body

Expected error: Item 1 is missing ‘header’ and ‘body’.

``` lua
{{< accordion yaml-missing-both >}}
```

**Accordion Error: 'yaml-missing-both': Item 1 is missing 'header' and 'body'.**

## YAML multiple items with partial missing

Expected error: Item 3 is missing ‘body’ (items 1, 2, 4 should render).

``` lua
{{< accordion yaml-many-items >}}
```

**Item 1**

This is the body content for item 1

------------------------------------------------------------------------

**Item 2**

This is the body content for item 2

------------------------------------------------------------------------

**Accordion Error: 'yaml-many-items': Item 3 is missing 'body'.**

------------------------------------------------------------------------

**Item 4**

This is the body content for item 4

## Inline label only - no header/body/items

Expected error: ‘label’ kwarg specified without ‘header’/‘body’ or
‘items’ kwargs.

``` lua
{{< accordion label="inline-empty" >}}
```

**Accordion Error: 'inline-empty': 'label' kwarg specified without 'header'/'body' or 'items' kwargs.**

## Inline missing body

Expected error: ‘body’ kwarg is missing.

``` lua
{{< accordion label="inline-missing-body" header="Click here to view contents" >}}
```

**Accordion Error: 'inline-missing-body': 'body' kwarg is missing.**

## Inline missing header

Expected error: ‘header’ kwarg is missing.

``` lua
{{< accordion label="inline-missing-header" body="This content is defined inline" >}}
```

**Accordion Error: 'inline-missing-header': 'header' kwarg is missing.**

## Inline header/body mixed with items

Expected error: Use either ‘header’/‘body’ or ‘items’, not both.

``` lua
{{< accordion label="inline-mixed" header="Header" body="Body" items='[{"header":"H","body":"B"}]' >}}
```

**Accordion Error: 'inline-mixed': Use either 'header'/'body' or 'items', not both.**

## Inline bad JSON in items

Expected error: Missing ‘header’ and ‘body’.

``` lua
{{< accordion label="inline-bad-json" items='not valid json' >}}
```

**Accordion Error: 'inline-bad-json': Missing 'header' and 'body'.**

## Inline JSON item missing header

Expected error: Item 2 is missing ‘header’.

``` lua
{{< accordion label="inline-json-no-header" items='[{"header":"Item 1","body":"Body 1"},{"body":"Body 2"}]' >}}
```

**Item 1**

Body 1

------------------------------------------------------------------------

**Accordion Error: 'inline-json-no-header': Item 2 is missing 'header'.**

## Inline JSON item missing body

Expected error: Item 1 is missing ‘body’.

``` lua
{{< accordion label="inline-json-no-body" items='[{"header":"Item 1"},{"header":"Item 2","body":"Body 2"}]' >}}
```

**Accordion Error: 'inline-json-no-body': Item 1 is missing 'body'.**

------------------------------------------------------------------------

**Item 2**

Body 2

# Success tests

These tests should each render a working accordion.

## YAML simple single item

``` lua
{{< accordion yaml-simple >}}
```

**Click here to view contents**

This content is defined in the document yaml

## YAML same label reused

``` lua
{{< accordion yaml-simple >}}
```

**Click here to view contents**

This content is defined in the document yaml

## YAML collapsed state

``` lua
{{< accordion yaml-collapsed >}}
```

**This is collapsed (default)**

Collapsed body content

------------------------------------------------------------------------

**This is expanded**

Expanded body content

## YAML custom id

``` lua
{{< accordion yaml-custom-id >}}
```

**Item with custom id**

Custom id body

## YAML id conflict

``` lua
{{< accordion yaml-id-conflict >}}
```

**Duplicate**

duplicate

------------------------------------------------------------------------

**Duplicate**

duplicate

## YAML markdown formatting

``` lua
{{< accordion yaml-markdown >}}
```

****Bold header****

This is **bold** and *italic*

## YAML multiline markdown

``` lua
{{< accordion yaml-multiline-markdown >}}
```

****Multiline markdown header****

This is multiline content.

This is **bold** and *italic*.

- List item 1
- List item 2

| Col1 | Col2 |
|------|------|
| A    | B    |

## YAML HTML formatting

``` lua
{{< accordion yaml-html >}}
```

**<b>HTML bold header</b>**

This is <b>bold</b> and <i>italic</i>

## YAML multiline HTML

``` lua
{{< accordion yaml-multiline-html >}}
```

**<b>Multiline HTML header</b>**
<p>

This is a paragraph.
</p>

<ul>

<li>

HTML list item 1
</li>

<li>

HTML list item 2
</li>

</ul>

## Inline simple

``` lua
{{< accordion label="inline-simple" header="Click here to view contents" body="This content is defined inline" >}}
```

**Click here to view contents**

This content is defined inline

## Inline double quoted hyphenated label

``` lua
{{< accordion label=""my-accordion"" header="Click to expand" body="This is the content of the accordion." >}}
```

**Click to expand**

This is the content of the accordion.

## Inline collapsed false

``` lua
{{< accordion label="inline-expanded" header="This starts expanded" body="Expanded content by default." collapsed="false" >}}
```

**This starts expanded**

Expanded content by default.

## Inline with custom id

``` lua
{{< accordion label="inline-custom-id" header="Custom item id" body="Custom ids are useful when you need anchor links." id="custom-item-1" >}}
```

**Custom item id**

Custom ids are useful when you need anchor links.

## Inline multi items via JSON

``` lua
{{< accordion label="inline-multi" items='[{"header":"Inline Item 1","body":"Content for item 1."},{"header":"Inline Item 2","body":"Content for item 2.","collapsed":false}]' >}}
```

**Inline Item 1**

Content for item 1.

------------------------------------------------------------------------

**Inline Item 2**

Content for item 2.

## Inline multi with custom id via JSON

``` lua
{{< accordion label="inline-multi-id" items='[{"header":"Item A","body":"Body A","id":"item-a"},{"header":"Item B","body":"Body B"}]' >}}
```

**Item A**

Body A

------------------------------------------------------------------------

**Item B**

Body B

## Inline markdown formatting

``` lua
{{< accordion label="inline-md" header="**Bold header**" body="This is **bold** and *italic*" >}}
```

****Bold header****

This is **bold** and *italic*

## Inline HTML formatting

``` lua
{{< accordion label="inline-html" header="<b>HTML bold header</b>" body="This is <b>bold</b> and <i>italic</i>" >}}
```

**<b>HTML bold header</b>**

This is <b>bold</b> and <i>italic</i>

## Inline JSON items with markdown

``` lua
{{< accordion label="inline-json-md" items='[{"header":"**Bold JSON header**","body":"This is **bold** and *italic*."},{"header":"Second item","body":"- List item 1\n- List item 2"}]' >}}
```

****Bold JSON header****

This is **bold** and *italic*.

------------------------------------------------------------------------

**Second item**

- List item 1
- List item 2

## Inline JSON items with HTML

``` lua
{{< accordion label="inline-json-html" items='[{"header":"<b>HTML JSON header</b>","body":"This is <b>bold</b> and <i>italic</i>."},{"header":"Second item","body":"<ul><li>Item 1</li><li>Item 2</li></ul>"}]' >}}
```

**<b>HTML JSON header</b>**

This is <b>bold</b> and <i>italic</i>.

------------------------------------------------------------------------

**Second item**
<ul>

<li>

Item 1
</li>

<li>

Item 2
</li>

</ul>
