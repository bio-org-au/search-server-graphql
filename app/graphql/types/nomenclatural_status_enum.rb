# https://github.com/rmosolgo/graphql-ruby/blob/master/guides/type_definitions/enums.md
class Types::NomenclaturalStatusEnum < Types::BaseEnum
  value "ISONYM",                           "Isonym"
  value "LEGITIMATE",                       "Legitimate"
  value "MANUSCRIPT",                       "manuscript"
  value "NOM_ALT",                          "nom. alt."
  value "NOM_ALT_NOM_ILLEG",                "nom. alt., nom. illeg"
  value "NOM_CONS",                         "nom. cons."
  value "NOM_CONS_NOM_ALT",                 "nom. cons., nom. alt."
  value "NOM_CONS_ORTH_CONS",               "nom. cons., orth. cons."
  value "NOM_CULT",                         "nom. cult."
  value "NOM_CULT_NOM_ALT",                 "nom. cult., nom. alt."
  value "NOM_ET_ORTH_CONS",                 "nom. et orth. cons."
  value "NOM_ET_TYP_CONS",                  "nom. et typ. cons."
  value "NOM_ILLEG",                        "nom. illeg."
  value "NOM_ILLEG_NOM_REJ",                "nom. illeg., nom. rej."
  value "NOM_ILLEG_NOM_SUPERFL",            "nom. illeg., nom. superfl."
  value "NOM_INVAL",                        "nom. inval."
  value "NOM_INVAL_NOM_ALT",                "nom. inval., nom. alt."
  value "NOM_INVAL_NOM_AMBIG",              "nom. inval., nom. ambig."
  value "NOM_INVAL_NOM_CONFUS",             "nom. inval., nom. confus."
  value "NOM_INVAL_NOM_NUD",                "nom. inval., nom. nud."
  value "NOM_INVAL_NOM_PROV",               "nom. inval., nom. prov."
  value "NOM_INVAL_NOM_SUBNUD",             "nom. inval., nom. subnud."
  value "NOM_INVAL_OPERA_UTIQUE_OPPRESSA",  "nom. inval., opera utique oppressa"
  value "NOM_INVAL_PRO_SYN",                "nom. inval., pro syn."
  value "NOM_INVAL_TAUTONYM",               "nom. inval., tautonym"
  value "NOM_REJ",                          "nom. rej."
  value "NOM_SUPERFL",                      "nom. superfl."
  value "NOMINA_UTIQUE_REJICIENDA",         "nomina utique rejicienda"
  value "ORTH_CONS",                        "orth. cons."
  value "ORTH_VAR",                         "orth. var."
  value "TYP_CONS",                         "typ. cons."
end