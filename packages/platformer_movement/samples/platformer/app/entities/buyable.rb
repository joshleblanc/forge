class Buyable < Forge::Entity 
    script Forge::Scripts::LdtkEntityScript.new
    script BuyableScript.new
    script Forge::Scripts::PromptScript.new(prompt: "Press E to buy!")
    script Forge::Scripts::LabelScript.new
end