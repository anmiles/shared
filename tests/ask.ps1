@(
    @{
        Input = "'Old value' => ''"
        Value = (ask -silent -value "Old value" -new_value "");
        Expect = "Old value";
        Comment = "Should pass value if new_value is empty";
    },
    @{
        Input = "'Old value' => ''"
        Value = (ask -silent -value "Old value" -new_value "" -default_new_value "Default value");
        Expect = "Default value";
        Comment = "Should pass default_new_value if any and new value is empty";
    },
    @{
        Input = "'Old value' => 'New value'"
        Value = (ask -silent -value "Old value" -new_value "New value");
        Expect = "New value";
        Comment = "Should set new_value if any";
    },
    @{
        Input = "'Old value' => 'New value'"
        Value = (ask -silent -value "Old value" -new_value "New value" -default_new_value "Default value");
        Expect = "New value";
        Comment = "Should set new_value if any even if default_new_value any";
    },
    @{
        Input = "'Old value' => '* new'"
        Value = (ask -silent -value "Old value" -new_value "* new");
        Expect = "* new";
        Comment = "Should set new_value as is even if starts with asterisk";
    },
    @{
        Input = "'Old value' => '*'"
        Value = (ask -silent -value "Old value" -new_value "*");
        Expect = "*";
        Comment = "Should set new_value as is even if asterisk";
    },
    @{
        Input = "'Old value' => 'New value'"
        Value = (ask -silent -value "Old value" -new_value "New value" -append);
        Expect = "New value";
        Comment = "Should set new_value as is if append and new_value doesn't start with asterisk";
    },
    @{
        Input = "'Old value' => '* new'"
        Value = (ask -silent -value "Old value" -new_value "* new" -append);
        Expect = "Old value * new";
        Comment = "Should append new_value if append and new_value starts with asterisk";
    },
    @{
        Input = "'Old value * old' => '* new'"
        Value = (ask -silent -value "Old value * old" -new_value "* new" -append);
        Expect = "Old value * new";
        Comment = "Should replace comment if append and new_value starts with asterisk";
    },
    @{
        Input = "'Old value * old * old2' => '* new'"
        Value = (ask -silent -value "Old value * old * old2" -new_value "* new" -append);
        Expect = "Old value * new";
        Comment = "Should replace all comments if append and new_value starts with asterisk";
    },
    @{
        Input = "'Old value' => '*'"
        Value = (ask -silent -value "Old value" -new_value "*" -append);
        Expect = "Old value";
        Comment = "Should return old value if no comments and append and new_value is asterisk";
    },
    @{
        Input = "'Old value * old' => '*'"
        Value = (ask -silent -value "Old value * old" -new_value "*" -append);
        Expect = "Old value";
        Comment = "Should remove comment if any and append and new_value is asterisk";
    },
    @{
        Input = "'Old value * old * old2' => '*'"
        Value = (ask -silent -value "Old value * old * old2" -new_value "*" -append);
        Expect = "Old value";
        Comment = "Should remove comments if any and append and new_value is asterisk";
    },
    @{
        Input = "'Old value * old * old2' => '* '"
        Value = (ask -silent -value "Old value * old * old2" -new_value "* " -append);
        Expect = "Old value";
        Comment = "Should remove comments if any and append and new_value is asterisk with spaces";
    },
    @{
        Input = "'Old value * old * old2' => '** new '"
        Value = (ask -silent -value "Old value * old * old2" -new_value "** new" -append);
        Expect = "Old value * old * new";
        Comment = "Should replace only last comment if append and new_value starts with two asterisks";
    },
    @{
        Input = "'Old value * old * old2' => '**'"
        Value = (ask -silent -value "Old value * old * old2" -new_value "**" -append);
        Expect = "Old value * old";
        Comment = "Should replace only last comment if append and new_value is two asterisks";
    },
    @{
        Input = "'Old value * old * old2' => '** '"
        Value = (ask -silent -value "Old value * old * old2" -new_value "**  " -append);
        Expect = "Old value * old";
        Comment = "Should replace only last comment if append and new_value is two asterisks and spaces";
    },
    @{
        Input = "'Old value * old * old2' => '*+ new'"
        Value = (ask -silent -value "Old value * old * old2" -new_value "*+ new" -append);
        Expect = "Old value * old * old2 * new";
        Comment = "Should append comment if append and new_value starts with asterisk and plus";
    },
    @{
        Input = "'Old value * old * old2' => '*+'"
        Value = (ask -silent -value "Old value * old * old2" -new_value "*+" -append);
        Expect = "Old value * old * old2";
        Comment = "Should keep comments if append and new_value is asterisk and plus";
    },
    @{
        Input = "'Old value * old * old2' => '*+ '"
        Value = (ask -silent -value "Old value * old * old2" -new_value "*+  " -append);
        Expect = "Old value * old * old2";
        Comment = "Should keep comments if append and new_value is asterisk and plus and spaces";
    },
    @{
        Input = "'Old value * old * old2 * old3' => '*-'"
        Value = (ask -silent -value "Old value * old * old2 * old3" -new_value "*- new" -append);
        Expect = "Old value * old * new";
        Comment = "Should replace two last comments if append and new_value starts with asterisks and minus";
    },
    @{
        Input = "'Old value * old * old2' => '*-'"
        Value = (ask -silent -value "Old value * old * old2" -new_value "*- new" -append);
        Expect = "Old value * new";
        Comment = "Should replace comments if two if append and new_value starts with asterisks and minus";
    },
    @{
        Input = "'Old value * old' => '*-'"
        Value = (ask -silent -value "Old value * old" -new_value "*- new" -append);
        Expect = "Old value * new";
        Comment = "Should replace comments if less than two if append and new_value starts with asterisks and minus";
    },
    @{
        Input = "'Old value * old * old2 * old3' => '*-'"
        Value = (ask -silent -value "Old value * old * old2 * old3" -new_value "*-" -append);
        Expect = "Old value * old";
        Comment = "Should replace two last comments if append and new_value is asterisks and minus";
    },
    @{
        Input = "'Old value * old * old2 * old3' => '*-'"
        Value = (ask -silent -value "Old value * old * old2 * old3" -new_value "*-  " -append);
        Expect = "Old value * old";
        Comment = "Should replace two last comments if append and new_value is asterisks and minus and spaces";
    }
)
