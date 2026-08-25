defmodule PhoenixPaper.HelpersTest do
  use ExUnit.Case, async: true

  alias PhoenixPaper.Helpers

  describe "classes/3" do
    test "paperize=true merges paper_classes and extra_class" do
      result = Helpers.classes(true, "bg-pp-primary", "mt-2")
      assert result =~ "bg-pp-primary"
      assert result =~ "mt-2"
    end

    test "paperize=false drops paper_classes entirely, keeping only extra_class" do
      result = Helpers.classes(false, "bg-pp-primary", "mt-2")
      refute result =~ "bg-pp-primary"
      assert result =~ "mt-2"
    end
  end

  describe "toggle_label_classes/1" do
    test "always includes the structural flex layout, regardless of what's passed in" do
      assert Helpers.toggle_label_classes(nil) =~ "inline-flex"
      assert Helpers.toggle_label_classes(nil) =~ "items-center"
      assert Helpers.toggle_label_classes("my-class") =~ "inline-flex"
      assert Helpers.toggle_label_classes("my-class") =~ "items-center"
    end

    test "merges extra_class alongside the structural layout" do
      assert Helpers.toggle_label_classes("my-class") =~ "my-class"
    end

    test "nil extra_class is fine — just the structural layout" do
      result = Helpers.toggle_label_classes(nil)
      assert result =~ "inline-flex"
      assert result =~ "cursor-pointer"
    end
  end
end
