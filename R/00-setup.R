## Create project
usethis::create_project('~/Desktop/osca_playground_leo')

## Start this setup file
usethis::use_r('00-setup.R')

## Start git repo
usethis::use_git()

## Use GitHub
usethis::browse_github_token()
usethis::edit_r_environ() ## then restart R
usethis::use_github() ## commit first, then run this command

## Start 01-intro notes
usethis::use_r('01-introduction.R')
