#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ModFW - node test suite.
#----------------------------------------------------------------------------
# +++++
$(call Last-Segment-UN)
ifndef ${LastSegUN}.SegID
$(call Enter-Segment,ModFW - node test suite.)
# -----
$(call Use-Segment,nodes)

$(call Declare-Suite,${Seg},Verify the node macros.)

_macro := verify-node-not-declared
define _help
${_macro}
  Verify a node is not declared and its attributes are not defined.
  Parameters:
    1 = The node to verify.
endef
help-${_macro} := ${_help}
define ${_macro}
  $(call Enter-Macro,$(0),$(1))
  $(if $(call node-is-declared,$(1)),
    $(call FAIL,Node $(1) should not be declared.)
  ,
    $(call PASS,Node $(1) is not declared.)
  )
  $(foreach _a,${node_attributes},
    $(if $(call Is-Not-Defined,${_a}),
      $(call PASS,Node attribute ${_a} is not defined.)
    ,
      $(call FAIL,Node attribute ${_a} is defined.)
    )
  )
  $(call Exit-Macro)
endef

_macro := verify-node-is-declared
define _help
${_macro}
  Verify that a node is declared and its attributes are defined.
  Parameters:
    1 = The node to verify.
endef
help-${_macro} := ${_help}
define ${_macro}
  $(call Enter-Macro,$(0),$(1))
  $(if $(call node-is-declared,$(1)),
    $(call PASS,Node $(1) is declared.)
  ,
    $(call FAIL,Node $(1) is not be declared.)
  )
  $(foreach _a,${node_attributes},
    $(if $(call Is-Not-Defined,${_a}),
      $(call FAIL,Node attribute ${_a} is not defined.)
    ,
      $(call PASS,Node attribute ${_a} is defined.)
    )
  )
  $(call Exit-Macro)
endef

_macro := verify-node-exists
define _help
${_macro}
  Verify a node exists meaning the node path is a valid file system path.
  The node must have been previously declared.
  Parameters:
    1 = The node to verify.
endef
help-${_macro} := ${_help}
define ${_macro}
  $(call Enter-Macro,$(0),$(1))
  $(call verify-node-is-declared,$(1))
  $(if $(call node-exists,$(1)),
    $(call PASS,Node $(1) has a valid path.)
  ,
    $(call FAIL,Node $(1) path does not exist.)
  )
  $(call Exit-Macro)
endef

_macro := verify-node-does-not-exist
define _help
${_macro}
  Verify a node does not exist meaning the node path is not a valid file system
  path.
  The node must have been previously declared.
  Parameters:
    1 = The node to verify.
endef
help-${_macro} := ${_help}
define ${_macro}
  $(call Enter-Macro,$(0),$(1))
  $(call verify-node-is-declared,$(1))
  $(if $(call node-exists,$(1)),
    $(call FAIL,Node $(1) has a valid path and should not.)
  ,
    $(call PASS,Node $(1) path does not exist.)
  )
  $(call Exit-Macro)
endef

_macro := verify-is-root-node
define _help
${_macro}
  Verify a node is correctly structured as a root node. A root node has no
  parent.
  Parameters:
    1 = The node to verify.
endef
help-${_macro} := ${_help}
define ${_macro}
  $(call Enter-Macro,$(0),$(1))
  $(call verify-node-is-declared,$(1))
  $(if ${$(1).parent},
    $(call FAIL,Node $(1) has a parent and should not.)
  ,
    $(call PASS,Node $(1) is a root node.)
  )
  $(call Exit-Macro)
endef

_macro := verify-is-child-node
define _help
${_macro}
  Verify a node is correctly structured as a child node. A child node has a
  parent.
  Parameters:
    1 = The node to verify.
endef
help-${_macro} := ${_help}
define ${_macro}
  $(call Enter-Macro,$(0),$(1))
  $(call verify-node-is-declared,$(1))
  $(if ${$(1).parent},
    $(call PASS,Node $(1) is a child node.)
    $(call Test-Info,Verifying parent node ${$(1).parent} is declared.)
    $(call verify-node-is-declared,${$(1).parent})
  ,
    $(call FAIL,Child node $(1) has no parent and should.)
  )
  $(call Exit-Macro)
endef

_macro := verify-is-child-of-parent
define _help
${_macro}
  Verify a node is a child of its parent node.
  Parameters:
    1 = The node to verify.
endef
help-${_macro} := ${_help}
define ${_macro}
  $(call Enter-Macro,$(0),$(1))
  $(call verify-node-is-declared,$(1))
  $(if ${$(1).parent},
    $(call PASS,Node $(1) is a child node.)
    $(if $(filter $(1),${${$(1).parent}.children})
      $(call PASS,Node $(1) is a child of ${$(1).parent}.)
    ,
      $(call FAIL,Node $(1) is NOT a child of ${$(1).parent}.)
    )
  ,
    $(call FAIL,Child node $(1) has no parent and should.)
  )
  $(call Exit-Macro)
endef

_macro := verify-is-child-of-node
define _help
${_macro}
  Verify a node is a child of the parent node.
  Parameters:
    1 = The node to verify.
    2 = The parent node.
endef
help-${_macro} := ${_help}
define ${_macro}
  $(call Enter-Macro,$(0),$(1))
  $(call verify-node-is-declared,$(1))
  $(call verify-node-is-declared,$(2))
  $(if ${$(1).parent},
    $(call PASS,Node $(1) is a child node.)
    $(if $(filter $(1),${$(2).children})
      $(call PASS,Node $(1) is a child of $(2).)
    ,
      $(call FAIL,Node $(1) is NOT a child of $(2).)
    )
  ,
    $(call FAIL,Child node $(1) has no parent and should.)
  )
  $(call Exit-Macro)
endef

_macro := verify-is-not-child-of-node
define _help
${_macro}
  Verify a node is not a child of the parent node. The child node must have
  been undeclared.
  Parameters:
    1 = The node to verify.
    2 = The parent node.
endef
help-${_macro} := ${_help}
define ${_macro}
  $(call Enter-Macro,$(0),$(1) $(2))
  $(call verify-node-not-declared,$(1))
  $(call verify-node-is-declared,$(2))
  $(if $(call is-a-child-of,$(1),$(2)),
    $(call FAIL,Node $(1) is a child of $(2).)
  ,
    $(call PASS,Node $(1) is NOT a child of $(2).)
  )
  $(call Exit-Macro)
endef

$(call Declare-Test,nonexistent-nodes)
define _help
${.TestUN}
  Verify messages, warnings and, errors for when nodes do not exist.
endef
help-${.TestUN} := ${_help}
${.TestUN}.Prereqs :=
define ${.TestUN}
  $(call Enter-Macro,$(0))
  $(call Begin-Test,$(0))

  $(call Test-Info,Testing node has not been declared.)
  $(eval _node := does-not-exist)
  $(call verify-node-not-declared,${_node})

  $(call Test-Info,Testing node does not exist.)
  $(call verify-node-does-not-exist,${_node})

  $(call End-Test)
  $(call Exit-Macro)
endef

$(call Declare-Test,declare-root-nodes)
define _help
${.TestUN}
  Verify declaring and undeclaring root nodes.
endef
help-${.TestUN} := ${_help}
${.TestUN}.Prereqs := ${.SuiteN}.nonexistent-nodes
define ${.TestUN}
  $(call Enter-Macro,$(0))
  $(call Begin-Test,$(0))

  $(eval _node := drn1)
  $(call verify-node-not-declared,${_rn})

  $(call Test-Info,Verify root node must have a path.)

  $(call Expect-Error,Path for root node ${_rn} has not been provided.)
  $(call declare-root-node,${_rn})
  $(call Verify-Error)

  $(call verify-node-not-declared,${_rn})

  $(call Test-Info,Verify root node can be declared.)

  $(call Expect-No-Error)
  $(call declare-root-node,${_rn},${TESTING_PATH})
  $(call Verify-No-Error)

  $(call verify-node-is-declared,${_rn})

  $(call Test-Info,Verify root node can be undeclared.)

  $(call Expect-No-Error)
  $(call undeclare-root-node,${_rn})
  $(call Verify-No-Error)

  $(call verify-node-not-declared,${_rn})

  $(call Test-Info,Verify root node cannot be undeclared more than once.)

  $(call Expect-Error,Node ${_rn} is NOT declared -- NOT undeclaring.)
  $(call undeclare-root-node,${_rn})
  $(call Verify-Error)

  $(call End-Test)
  $(call Exit-Macro)
endef

$(call Declare-Test,create-root-nodes)
define _help
${.TestUN}
  Verify creating and destroying root nodes.
endef
help-${.TestUN} := ${_help}
${.TestUN}.Prereqs := ${.SuiteN}.declare-root-nodes
define ${.TestUN}
  $(call Enter-Macro,$(0))
  $(call Begin-Test,$(0))

  $(eval _rn := ${Seg}.crn1)

  $(call Test-Info,Testing node is not declared.)
  $(call verify-node-not-declared,${_rn})

  $(call Test-Info,Testing node does not exist.)
  $(call declare-root-node,${_rn},${TESTING_PATH})
  $(call verify-node-does-not-exist,${_rn})

  $(call Test-Info,Testing node can be created.)
  $(call create-node,${_rn})
  $(call verify-node-exists,${_rn})

  $(call destroy-node,${_rn})
  $(call verify-node-does-not-exist,${_rn})

  $(call undeclare-root-node,${_rn})

  $(call End-Test)
  $(call Exit-Macro)
endef

$(call Declare-Test,declare-child-nodes)
define _help
${.TestUN}
  Verify declaring and undeclaring child nodes.
endef
help-${.TestUN} := ${_help}
${.TestUN}.Prereqs := ${.SuiteN}.declare-root-nodes
define ${.TestUN}
  $(call Enter-Macro,$(0))
  $(call Begin-Test,$(0))

  $(eval _rn := ${Seg}.dcnr1)
  $(eval _cn := dcnc1)

  $(call verify-node-not-declared,${_rn})
  $(call verify-node-not-declared,${_cn})

  $(call Test-Info,Verify root node must have a path.)

  $(call Expect-Error,The parent for node ${_cn} has not been specified.)
  $(call declare-child-node,${_cn})
  $(call Verify-Error)

  $(call Test-Info,Verify parent node must have been declared.)

  $(call Expect-Error,Parent node ${_rn} has not been declared.)
  $(call declare-child-node,${_cn},${_rn})
  $(call Verify-Error)

  $(call verify-node-not-declared,${_cn})

  $(call Test-Info,Verify child node can be declared.)

  $(call declare-root-node,${_rn},${TESTING_PATH})

  $(call Expect-No-Error)
  $(call declare-child-node,${_cn},${_rn})
  $(call Verify-No-Error)

  $(call verify-node-is-declared,${_cn})

  $(call verify-is-child-of-parent,${_cn})

  $(call verify-is-child-of-node,${_cn},${_rn})

  $(call Test-Info,Verify child node can be undeclared.)

  $(call Expect-No-Error)
  $(call undeclare-child-node,${_cn})
  $(call Verify-No-Error)

  $(call verify-node-not-declared,${_cn})

  $(call verify-is-not-child-of-node,${_cn},${_rn})

  $(call Test-Info,Verify child node cannot be undeclared more than once.)

  $(call Expect-Error,Node ${_cn} is NOT declared -- NOT undeclaring.)
  $(call undeclare-child-node,${_cn})
  $(call Verify-Error)

  $(call undeclare-root-node,${_rn})

  $(call End-Test)
  $(call Exit-Macro)
endef

$(call Declare-Test,declare-grandchild-nodes)
define _help
${.TestUN}
  Verify declaring and undeclaring grandchild nodes.
endef
help-${.TestUN} := ${_help}
${.TestUN}.Prereqs := \
${.SuiteN}.declare-root-nodes \
${.SuiteN}.declare-child-nodes
define ${.TestUN}
  $(call Enter-Macro,$(0))
  $(call Begin-Test,$(0))

  $(eval _rn := ${Seg}.dgcnr1)
  $(eval _cn := dgcnc1)
  $(eval _gcn := dgcngc1)

  $(call verify-node-not-declared,${_rn})
  $(call verify-node-not-declared,${_cn})
  $(call verify-node-not-declared,${_gcn})

  $(call declare-root-node,${_rn},${TESTING_PATH})
  $(call declare-child-node,${_cn},${_rn})

  $(call Expect-No-Error)
  $(call declare-child-node,${_gcn},${_cn})
  $(call Verify-No-Error)

  $(call verify-node-is-declared,${_gcn})

  $(call verify-is-child-of-parent,${_gcn})
  $(call verify-is-child-of-node,${_gcn},${_cn})
  $(call verify-is-not-child-of-node,${_gcn},${_rn})

  $(call Test-Info,Verify child node cannot be undeclared.)
  $(call Expect-Error,Child node $(1) has children -- NOT undeclaring.)
  $(call undeclare-child-node,${_cn})
  $(call Verify-Error)

  $(call Test-Info,Verify grandchild node can be undeclared.)
  $(call Expect-No-Error)
  $(call undeclare-child-node,${_gcn})
  $(call Verify-No-Error)

  $(call verify-node-not-declared,${_gcn})

  $(call verify-is-not-child-of-node,${_gcn},${_cn})

  $(call Test-Info,Verify child node can now be undeclared.)
  $(call Expect-No-Error)
  $(call undeclare-child-node,${_cn})
  $(call Verify-No-Error)

  $(call undeclare-root-node,${_rn})

  $(call End-Test)
  $(call Exit-Macro)
endef

$(call Declare-Test,create-child-nodes)
define _help
${.TestUN}
  Verify creating and destroying child nodes.
endef
help-${.TestUN} := ${_help}
${.TestUN}.Prereqs := \
  ${.SuiteN}.declare-child-nodes \
  ${.SuiteN}.create-root-nodes
define ${.TestUN}
  $(call Enter-Macro,$(0))
  $(call Begin-Test,$(0))

  $(eval _rn := ${Seg}.ccnr1)
  $(eval _cn := ccnc1)

  $(call Test-Info,Testing node is not declared.)
  $(call verify-node-not-declared,${_rn})

  $(call Test-Info,Creating test root node.)
  $(call declare-root-node,${_rn},${TESTING_PATH})
  $(call create-node,${_rn})

  $(call Test-Info,Creating test child node.)
  $(call declare-child-node,${_cn},${_rn})
  $(call create-node,${_cn})
  $(call verify-node-exists,${_cn})

  $(call destroy-node,${_cn})
  $(call verify-node-does-not-exist,${_cn})

  $(call undeclare-child-node,${_cn})

  $(call Test-Info,Destroying test child node.)
  $(call destroy-node,${_rn})
  $(call undeclare-root-node,${_rn})


  $(call End-Test)
  $(call Exit-Macro)
endef

$(call Declare-Test,create-grandchild-nodes)
define _help
${.TestUN}
  Verify creating and destroying grandchild nodes.
endef
help-${.TestUN} := ${_help}
${.TestUN}.Prereqs := \
  ${.SuiteN}.declare-grandchild-nodes \
  ${.SuiteN}.create-root-nodes
define ${.TestUN}
  $(call Enter-Macro,$(0))
  $(call Begin-Test,$(0))

  $(eval _rn := ${Seg}.cgcnr1)
  $(eval _cn := cgcnc1)
  $(eval _gcn := cgcngc1)

  $(call Test-Info,Testing node is not declared.)
  $(call verify-node-not-declared,${_rn})

  $(call Test-Info,Creating test root node.)
  $(call declare-root-node,${_rn},${TESTING_PATH})
  $(call create-node,${_rn})

  $(call Test-Info,Creating test child node.)
  $(call declare-child-node,${_cn},${_rn})
  $(call create-node,${_cn})

  $(call Test-Info,Creating test child node.)
  $(call declare-child-node,${_gcn},${_cn})
  $(call create-node,${_gcn})
  $(call verify-node-exists,${_gcn})

  $(call display-node-tree,${_rn})

  $(call destroy-node,${_gcn})
  $(call verify-node-does-not-exist,${_gcn})

  $(call display-node-tree,${_rn})

  $(call destroy-node,${_cn})
  $(call verify-node-does-not-exist,${_cn})

  $(call undeclare-child-node,${_cn})

  $(call Test-Info,Destroying test child node.)
  $(call destroy-node,${_rn})
  $(call undeclare-root-node,${_rn})


  $(call End-Test)
  $(call Exit-Macro)
endef

# +++++
# Postamble
# Define help only if needed.
_h := \
  $(or \
    $(call Is-Goal,help-${Seg}),\
    $(call Is-Goal,help-${SegUN}),\
    $(call Is-Goal,help-${SegID}))
ifneq (${_h},)
define _help
Make segment: ${Seg}.mk

This test suite verifies the macros related to managing nodes.

Defines the macros:

${help-display-node}
${help-display-node-tree}

$(foreach _t,${${.TestUN}.TestL},
${help-${_t}})

Uses:
  TESTING_PATH
    Where the test nodes are stored.

Command line goals:
  help-${Seg} or help-${SegUN} or help-${SegID}
    Display this help.
endef
${_h} := ${_help}
endif # help goal message.

$(call End-Declare-Suite)

$(call Exit-Segment)
else # <u>SegId exists
$(call Check-Segment-Conflicts)
endif # <u>SegId
# -----