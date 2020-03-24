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

## More general:
r_files <- dir('../osca_LIIGH_UNAM_2020/', pattern = '[0-9]+.*\\.R$')
for(i in seq_along(r_files)) {
    r_content <- glue::glue('# Notes for {r_files[i]}
# --------------------------------------
## Copy code from https://github.com/lcolladotor/osca_LIIGH_UNAM_2020/blob/master/{r_files[i]}

## Notes

        ')
    writeLines(r_content, here::here('R', r_files[i]))
}
