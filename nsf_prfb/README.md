# NSF PRFB Materials for 2023 Call: Genomes and environments

1. [Author Extraction](#1-Authors)

This repo will contain materials related to NSF PRFB calls for 2023, since so few examples exist. I won't upload all materials until after decisions based on some sensitive data. 

## 1. Author Extraction

The NSF (and many other funding agencies) ask for all associations for the last n-years. This repo contains a python script which takes as positional argument DOI and extracts coauthor names, publication year, and the authors affiliation. If the publication or the coauthor doesn't exist on crossref, then this script will output either that it can't be found at all, or [] for affiliations. 

This is particularly useful for the NSF PRFB COA (Collaborators and Other Affiliations) document, as of the time of this script. I found this works on at least half of all given DOIs, depending on how updated crossref is, but hopefully it helps with at least some large papers and establish frequent collaborators in an automated process

Works as of Nov 2023 using the conda enviroment specified in the `.yml` file. 

python Coauthor_Search.py DOIS.list 

It's not perfect, it will:

- Search for the DOI using crossref api.
- Extract coauthors and affiliations, publication date
- If there are duplicated coauthors across DOIs, keep the one with the affilation
- If the affiliation is missing, search crossref for a fuzzy search removing accents, middle name etc. 
- Sometimes this fuzzy search messes up publication date. 

In any case, I gave the script 33 DOIs, and it output publication dates, authors, and affiliations for 312 coauthors. It was unable to retrieve affiliations for another 200ish coauthors, so not perfect, but probably good enough. If you don't care about affiliations you can just write unknown affiliation and at least you have author names.

```
head final_table.txt
Unknown@Santos, Inês Alexandre Machado dos@
Unknown@Snell, Katherine R. S.@Center for Macroecology, Evolution and Climate, Natural History Museum of Denmark, University of Copenhagen, Copenhagen, Denmark
Unknown@van Bemmelen, Rob SA@
Unknown@Moe, Børge@
Unknown@Thorup, Kasper@Center for Macroecology, Evolution and Climate, Natural History Museum of Denmark, University of Copenhagen, Copenhagen, Denmark
2023-7@Vickery, Juliet A.@RSPB Centre for Conservation Science, Royal Society for the Protection of Birds  The Lodge, Sandy Bedfordshire SG19 2DL UK
2023-7@Mallord, John W.@RSPB Centre for Conservation Science, Royal Society for the Protection of Birds The Lodge Sandy UK
2023-7@Adams, William M.@Department of Geography University of Cambridge  Cambridge CB2 3EN UK
2023-7@Beresford, Alison E.@RSPB Centre for Conservation Science, Royal Society for the Protection of Birds  The Lodge, Sandy Bedfordshire SG19 2DL UK
2023-7@Both, Christiaan@Netherlands Institute of Ecology (NIOO‐KNAW)  PO Box 40 Heteren 6666ZG The Netherlands
```
