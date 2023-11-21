import requests
import json
import argparse
from unidecode import unidecode
from fuzzywuzzy import fuzz

def get_paper_info(doi):
    base_url = "https://api.crossref.org/works/"
    response = requests.get(base_url + doi)
    if response.status_code == 200:
        return json.loads(response.content)
    else:
        return None

def normalize_name(name):
    return unidecode(name).lower()

def is_name_match(author_name, target_family, target_given):
    author_parts = author_name.split(", ")
    target_family_parts = target_family.split(", ")
    target_given_parts = target_given.split(" ")

    if fuzz.partial_ratio(normalize_name(author_parts[0]), normalize_name(target_family_parts[0])) > 85:
        if len(author_parts) > 1 and fuzz.partial_ratio(normalize_name(author_parts[1]), normalize_name(" ".join(target_given_parts))) > 85:
            return True
    return False

def search_author_affiliation(family_name, given_name):
    base_url = "https://api.crossref.org/works?query.author="
    query_name = normalize_name(family_name + ", " + given_name)
    response = requests.get(base_url + query_name)
    if response.status_code == 200:
        works = json.loads(response.content).get('message', {}).get('items', [])
        for work in works:
            for author in work.get('author', []):
                if is_name_match(author.get('family', '') + ", " + author.get('given', ''), family_name, given_name):
                    affiliations = [aff.get('name') for aff in author.get('affiliation', [])]
                    return affiliations
    return None

def process_doi(doi):
    paper_info = get_paper_info(doi)
    coauthors = {}
    if paper_info and 'message' in paper_info:
        publication_date = paper_info['message'].get('published-print',
                                                     paper_info['message'].get('published-online', {}))
        date_parts = publication_date.get('date-parts', [[]])
        if date_parts[0]:
            formatted_date = '-'.join(map(str, date_parts[0]))
        else:
            formatted_date = 'Unknown'

        authors = paper_info['message'].get('author', [])
        for author in authors:
            name = author.get('family', '') + ", " + author.get('given', '')
            affiliation = author.get('affiliation', [])
            affiliation = affiliation[0].get('name', '') if affiliation else ''
            coauthors[name] = (formatted_date, affiliation)
    return coauthors

def main(dois):
    coauthor_table = {}
    for doi in dois:
        paper_data = process_doi(doi)
        for name, (date, affil) in paper_data.items():
            if name in coauthor_table:
                existing_date, existing_affil = coauthor_table[name]
                if affil or not existing_affil:
                    coauthor_table[name] = (max(date, existing_date), affil or existing_affil)
            else:
                coauthor_table[name] = (date, affil)

    for name, (date, affil) in coauthor_table.items():
        if not affil:
            family_name, given_name = name.split(", ")
            new_affil = search_author_affiliation(family_name, given_name)
            if new_affil:
                coauthor_table[name] = (date, new_affil[0])

    with open('final_table.txt', 'w') as file:
        for name, (date, affil) in coauthor_table.items():
            line = f"{date}@{name}@{affil}\n"
            file.write(line)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Retrieve coauthor information from DOIs')
    parser.add_argument('doi_file', type=str, help='File containing a list of DOIs')
    args = parser.parse_args()
    with open(args.doi_file, 'r') as file:
        dois = [line.strip() for line in file]
    main(dois)

