output "repositories" {
  value = {
    for k, r in merge(github_repository.this, github_repository.import_only) :
    k => { url = r.html_url, archived = r.archived }
  }
}
