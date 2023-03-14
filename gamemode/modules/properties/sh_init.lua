local MODULE = MODULE

MODULE.name = "Properties"
MODULE.author = "morgverd"
MODULE.description = "Make buildings into managed properties"

-- The resolution is the amount of cells that should be generated
-- for both the top row (x) and right column (y) areas. The higher
-- the number the better the precision. Recommended: 25
GNIL.Properties = GNIL.Properties or {
    _resolution = 25
}