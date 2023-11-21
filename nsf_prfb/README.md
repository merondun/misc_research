# NSF PRFB Materials for 2023 Call: Genomes and environments

1. [Author Extraction](#1-Authors)

This repo will contain materials related to NSF PRFB calls for 2023, since so few examples exist. I won't upload all materials until after decisions based on some sensitive data. 

## 1. Author Extraction

The NSF (and many other funding agencies) ask for all associations for the last n-years. This repo contains a python script which takes as positional argument DOI and extracts coauthor names, publication year, and the authors affiliation. If the publication or the coauthor doesn't exist on crossref, then this script will output either that it can't be found at all, or [] for affiliations. 

This is particularly useful for the NSF PRFB COA (Collaborators and Other Affiliations) document, as of the time of this script. I found this works on at least half of all given DOIs, depending on how updated crossref is, but hopefully it helps with at least some large papers and establish frequent collaborators in an automated process

python Extract_Coauthor_Details.py https://doi.org/10.1371/journal.pgen.1010901

Output is '@' separated so that you can `cat` all https files and then copy that directly into excel, and then use '@' as your column separator so that you always have 3 columns regardless of the tab/space separator in affiliations:  

```
cat https:__doi.org_10.1111_acv.12732_info.txt | tr '@' '\t'
Publication Date: 2022-4
Authors and Affiliations:
2022-4  Leighton, Gabriella R. M.       Department of Biological Sciences Institute for Communities and Wildlife in Africa University of Cape Town  Cape Town South Africa
2022-4  Bishop, Jacqueline M.   Department of Biological Sciences Institute for Communities and Wildlife in Africa University of Cape Town  Cape Town South Africa
2022-4  Merondun, Justin        Division of Evolutionary Biology Faculty of Biology LMU Munich  Planegg‐Martinsried Germany
2022-4  Winterton, Deborah J.   Cape Research Centre South African National Parks  Cape Town South Africa
2022-4  O’Riain, M. Justin      Department of Biological Sciences Institute for Communities and Wildlife in Africa University of Cape Town  Cape Town South Africa
2022-4  Serieys, Laurel E. K.   Department of Biological Sciences Institute for Communities and Wildlife in Africa University of Cape Town  Cape Town South Africa
```
