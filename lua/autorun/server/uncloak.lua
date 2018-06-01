hook.Add("TTTPrepareRound", "UnCloakAll",function()
    for k, v in pairs(player.GetAll()) do
        v:SetMaterial("models/glass")
    end
end
)