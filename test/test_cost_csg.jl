import Interfaces

@testset verbose=true "CBCSGs" begin
    Interfaces.test(CostBasedInterface)
end