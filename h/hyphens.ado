program define hyphens

local options "LINES(integer 1)"
parse "`*'"

local j = 1
while `j' <= `lines' {
			display "--------"
			local j = `j' + 1
			}
end
