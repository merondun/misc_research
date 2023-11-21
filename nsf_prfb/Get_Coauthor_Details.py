import requests
import json
import argparse

def get_paper_info(doi):
    base_url = "https://api.crossref.org/works/"
    response = requests.get(base_url + doi)
    if response.status_code == 200:
        return json.loads(response.content)
    else:
        return None

def main(doi):
    paper_info = get_paper_info(doi)

    # Filename to save the output
    filename = f"{doi.replace('/', '_')}_info.txt"

    with open(filename, 'w') as file:
        if paper_info and 'message' in paper_info:
            publication_date = paper_info['message'].get('published-print', 
                                                         paper_info['message'].get('published-online', {}))
            date_parts = publication_date.get('date-parts', [[]])
            if date_parts[0]:
                formatted_date = '-'.join(map(str, date_parts[0]))
            else:
                formatted_date = 'Unknown'

            file.write(f"Publication Date: {formatted_date}\n")
            file.write("Authors and Affiliations:\n")

            authors = paper_info['message'].get('author', [])
            for author in authors:
                name = author.get('family', '') + ", " + author.get('given', '')
                affiliation = author.get('affiliation', [])
                if affiliation:
                    affiliation = affiliation[0].get('name', '')
                file.write(f"{formatted_date}@{name}@{affiliation}\n")
        else:
            file.write("Paper information could not be retrieved.\n")

    print(f"Information saved to {filename}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Retrieve paper information using DOI')
    parser.add_argument('doi', type=str, help='The DOI of the paper')
    args = parser.parse_args()
    main(args.doi)

