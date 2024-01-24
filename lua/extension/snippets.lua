local luasnip = require 'luasnip'

local s = luasnip.snippet
local fmt = require("luasnip.extras.fmt").fmt
local i = luasnip.insert_node
local l = require("luasnip.extras").lambda
local t = luasnip.text_node
local f = luasnip.function_node
local rep = require("luasnip.extras").rep


luasnip.add_snippets("markdown", {
  s("title", fmt("---\ntitle: {}\n---\n# {}", { i(1, "name"), rep(1) })),
  s("noteh", fmt("---\ntitle: {}\n---\n# {}\n### Summary\n\n### Notes\n{}", { i(1, "name"), rep(1), i(0) })),
}, {
  key = "markdown",
})

-- yew snippets
-- function component
luasnip.add_snippets("rust", {
  s("fcomp", {
    t({"#[derive(Properties, PartialEq, Clone)]", ""}),
    t("pub struct "), i(1, "name"), t({"Props {}","", ""}),
    t("#[function_component("),rep(1), t({")]",""}),
    t("pub fn "), l(l._1:lower(), 1), t("(props: &"), rep(1), t({"Props) -> Html {", "", "\t"}),
    t({"html! {", "\t\t" }),
    i(0),
    t({"", "\t"}),
    t({"}", ""}),
    t({"}",""}),
  }),
})