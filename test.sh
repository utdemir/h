#!/usr/bin/env bash

function oneTimeSetUp() {
  unset HOME
  unset XDG_CONFIG_HOME
  unset H_GO
  unset H_WORKSPACE

  old_pwd="$(pwd)"

  tmp_gh="$(mktemp -d)"
  tmp_home="$(mktemp -d)"
  export HOME="$tmp_home"

  git config --global \
    "url.file://$tmp_gh.insteadOf" "https://github.com"
  git config --global "user.name" "H"
  git config --global "user.email" "h@h.co"

  for i in "nixos/nixpkgs" "nixos/nixops" "utdemir/dotfiles"; do
    mkdir -p "$tmp_gh/$i"
    (
      cd "$tmp_gh/$i"
      git init --quiet
      touch "$(basename $i)_file"
      git add "$(basename $i)_file"
      git commit --quiet -m "initial"
    )
  done

  local script_dir="$( dirname "${BASH_SOURCE[0]}" )"
  source "$script_dir/h.sh"
  h_init_bash
}

function setUp() {
  tmp_workspace="$(mktemp -d)"
  H_WORKSPACE="$tmp_workspace"

  tmp_cwd="$(mktemp -d)"
  cd "$tmp_cwd"
}

function tearDown() {
  cd "$old_pwd"
  rm -rf "$tmp_workspace"
  rm -rf "$tmp_cwd"
}

function oneTimeTearDown() {
  rm -rf "$tmp_home"
}

# TESTS BEGIN

function testEmptyArgs() {
  h
  assertEquals "$H_WORKSPACE" "$(pwd)"
}

function testSimple() {
  h nixos/nixpkgs 2>/dev/null
  assertEquals "$H_WORKSPACE/github.com/nixos/nixpkgs" "$(pwd)"
  assertTrue '[[ -e nixpkgs_file ]]'
}

function testExisting() {
  h nixos/nixpkgs 2>/dev/null
  rm "$H_WORKSPACE/github.com/nixos/nixpkgs/nixpkgs_file"

  cd
  h nixos/nixpkgs

  assertEquals "$H_WORKSPACE/github.com/nixos/nixpkgs" "$(pwd)"
  assertFalse '[[ -e nixpkgs_file ]]'
}

function testCompletionsAll() {
  h nixos/nixpkgs 2>/dev/null
  h utdemir/dotfiles 2>/dev/null

  cs="$(_h_get_completions "")"
  assertContains "$cs" "github.com/nixos/nixpkgs"
  assertContains "$cs" "github.com/utdemir/dotfiles"
}

function testCompletionsPrefix() {
  h nixos/nixpkgs 2>/dev/null
  h utdemir/dotfiles 2>/dev/null

  cs="$(_h_get_completions "dot")"
  assertContains "$cs" "github.com/utdemir/dotfiles"
  assertNotContains "$cs" "github.com/nixos/nixpkgs"
}

. shunit2
