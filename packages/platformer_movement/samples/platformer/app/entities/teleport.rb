class Teleport < Forge::Entity 
    script Forge::Scripts::LdtkEntityScript.new
    script TeleportScript.new
    script Forge::Scripts::PromptScript.new(prompt: "Press E to interact")
end