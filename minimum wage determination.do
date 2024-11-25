gl root "https://github.com/alfredoalvaradoenciso/minwage/raw/refs/heads/main/"

clear

input year elasticity
2004	0.25
2005	0.27
2006	0.36
2007	0.22
2008	0.20
2009	0.18
2010	0.18
2011	0.19
2012	0.15
2013	.
2014	.
2015	.
2016	.
2017	.
2018	.
2019	.
2020	.
2021	.
2022	.
2023	.
2024	.
end
tsset year
gen e_grow=elasticity/L.elasticity-1
egen e_grow_m=mean(e_grow)
gen e=elasticity
replace e=L.e*(1+e_grow_m/2) if elasticity==.
tempfile elasticity
save `elasticity'

use $root/peru_employment.dta, clear //ILOSTAT
destring time, gen(year)
keep obs_value year
tempfile l
save `l'

import excel $root/ipc_nacional.xlsx, sheet("Base Dic.2021") cellrange(A4:F158) firstrow clear // INEI
replace Año=Año[_n-1] if Año[_n]==. 
replace Anual="" if Anual=="-"
destring Anual, replace
rename Año year
collapse (mean) ipc_nacional=Anual, by(year)
tempfile ipc_nacional
save `ipc_nacional'

import excel $root/conference_board_tfp.xlsx, sheet("Annual") cellrange(BLW7:BLW82) firstrow clear // Conference Board
gen year=1949+_n
tempfile conference
save `conference'

use countrycode year ctfp cwtfp rtfpna rwtfpna if countrycode=="PER" using $root/pwt1001 , clear // PWT
tempfile pwt
save `pwt'

import delimited "https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PN02124PM/txt/1991-1/2024-9", delimiters("\t") clear encoding(UTF-8)
replace mesaño=subinstr(mesaño,"Ene","Jan",.)
replace mesaño=subinstr(mesaño,"Abr","Apr",.)
replace mesaño=subinstr(mesaño,"Ago","Aug",.)
replace mesaño=subinstr(mesaño,"Dic","Dec",.)
gen date_monthly = monthly(mesaño, "MY")
format date_monthly %tm
rename remuneracionesremuneraciónmínima rmv
gen year = 1960 + floor(date_monthly / 12)
collapse (mean) rmv, by(year)
tempfile rmv
save `rmv'


import delimited https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PM05000AA/txt/2001/2024, clear delimiters("\t") encoding(UTF-8)
rename (productobrutointernoporsectoresp año) (pbi year)
tempfile pbi
save `pbi'
import delimited https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PM05217PA/txt/2001/2024, clear delimiters("\t") encoding(UTF-8)
rename (índicespromedioanualvariaciónpor año) (ipc_lima year)
tempfile a
save `a'
import delimited https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PM05220PA/txt/2001/2024, clear delimiters("\t") encoding(UTF-8)
rename (índicespromedioanualvariaciónpor año) (ipc_lima_subyacente year)
merge 1:1 year  using  `a', nogen
merge 1:1 year  using  `pbi', nogen
merge 1:1 year  using  `pwt', nogen
merge 1:1 year  using  `conference', nogen
merge 1:1 year  using  `rmv', nogen
merge 1:1 year  using  `ipc_nacional', nogen
merge 1:1 year  using  `l', nogen
merge 1:1 year  using  `elasticity', nogen


gen pl=pbi*1000/obs_value

tsset year
foreach v of varlist rtfpna rwtfpna pl e {
gen `v'_pc=(`v'/L.`v'-1)
}

replace ipc_lima_subyacente=ipc_lima_subyacente/100
replace ipc_nacional=ipc_nacional/100
replace TheConferenceBoard=TheConferenceBoard/100
gen rmvtag=rmv if year==2024
replace e_pc=0

local rmv="rmv_teo"
gen `rmv'_pc=(ipc_nacional+TheConferenceBoard- e_pc/(1+e))
local initialyear=2013
gen `rmv'=rmv if year==`initialyear'
replace `rmv'=L.`rmv'*(1+`rmv'_pc) if year>=`initialyear'+1
gen `rmv'tag=round(`rmv',1) if year==2024
twoway line rmv year if year>=`initialyear' || line  `rmv' year if year>=`initialyear' || scatter `rmv'tag year if year==2024 , mlabel(`rmv'tag ) msymbol(none) mlabcolor(black) mlabsize(medium)  text(1125 2025 "1025") legend(order(1 "RMV observada" 2 "RMV teórica") col(2)) ytitle("Soles") name(a, replace) title("Con inflación nacional y PTF") xlabel(2012(4)2025)


local rmv="rmv_teo2"	
gen `rmv'_pc=(ipc_lima_subyacente+TheConferenceBoard - e_pc/(1+e))
local initialyear=2008
gen `rmv'=rmv if year==`initialyear'
replace `rmv'=L.`rmv'*(1+`rmv'_pc) if year>=`initialyear'+1
gen `rmv'tag=round(`rmv',1) if year==2023
twoway line rmv year if year>=`initialyear' || line  `rmv' year if year>=`initialyear' || scatter `rmv'tag year if year==2023 , mlabel(`rmv'tag ) msymbol(none) mlabcolor(black) mlabsize(medium)  text(1025 2025 "1025") legend(order(1 "RMV observada" 2 "RMV teorica")) ytitle("Soles") name(b, replace) title("Con inflación subyacente Lima y PTF") xlabel(2008(4)2024)

local rmv="rmv_teo3"
gen `rmv'_pc=(ipc_nacional+pl_pc - e_pc/(1+e))
local initialyear=2013
gen `rmv'=rmv if year==`initialyear'
replace `rmv'=L.`rmv'*(1+`rmv'_pc) if year>=`initialyear'+1
gen `rmv'tag=round(`rmv',1) if year==2023
twoway line rmv year if year>=`initialyear' || line  `rmv' year if year>=`initialyear' || scatter `rmv'tag year if year==2023 , mlabel(`rmv'tag ) msymbol(none) mlabcolor(black) mlabsize(medium)   text(1025 2025 "1025") legend(order(1 "RMV observada" 2 "RMV teorica")) ytitle("Soles") name(c, replace) title("Con inflación nacional y PL") xlabel(2012(4)2025)

local rmv="rmv_teo4"
gen `rmv'_pc=(ipc_lima_subyacente+pl_pc - e_pc/(1+e))
local initialyear=2008
gen `rmv'=rmv if year==`initialyear'
replace `rmv'=L.`rmv'*(1+`rmv'_pc) if year>=`initialyear'+1
gen `rmv'tag=round(`rmv',1) if year==2023
twoway line rmv year if year>=`initialyear' || line  `rmv' year if year>=`initialyear' || scatter `rmv'tag year if year==2023 , mlabel(`rmv'tag ) msymbol(none) mlabcolor(black) mlabsize(medium)  text(1025 2025 "1025") legend(order(1 "RMV observada" 2 "RMV teorica")) ytitle("Soles") name(d, replace) title("Con inflación subyacente Lima y PL") xlabel(2008(4)2024)

*grc1leg2 a b c d, leg(a) ycommon title(Salario Mínimo observado vs teórico simplificado) note("Fuente: The Conference Board, INEI, BCRP, ILO." "Nota: {&Delta}RMV teórica{sub:t} = inflación{sub:t}+ {&Delta}productividad{sub:t}")
*graph export C:\Users\aalvarado\Downloads\rmv_determination_sine.png, replace

grc1leg2 a b c d, leg(a) ycommon title("Salario Mínimo observado vs teórico en mercados concentrados") note("Fuente: The Conference Board, INEI, BCRP, ILO." "Nota: {&Delta}RMV teórica{sub:t} = inflación{sub:t}+ {&Delta}productividad{sub:t} - {&Delta}{&epsilon}{sub:t}/(1+{&epsilon}{sub:t}), donde {&epsilon} = elasticidad de la oferta laboral de Reyna y Céspedes (2016).")
graph export C:\Users\aalvarado\Downloads\rmv_determination_cone.png, replace
