const { BN, constants, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;

const ERC721Version = artifacts.require("ERC721Version");
const name1 = "TestContract";
const symbol = "TST";
const supply = 1000;
const price = 1000000;
const baseURI = "";

contract("ERC721Version", (accounts) => {
    let [alice, bob, chalie] = accounts;
    let contractInstance;
    beforeEach(async () => {
        token = await ERC721Version.new( name1,symbol);
    });
    describe("Instantiation", function () {
        it("Should be able to instantiate the contract name", async () => {
            expect(await token.name()).to.be.equal(name1);
        });
        it("Should be able to instantiate the contract symbol", async () => {
            expect(await token.symbol()).to.be.equal(symbol);
        });
        it("Should be able to instantiate the contract symbol", async () => {
            expect(await token.symbol()).to.be.equal(symbol);
        });

    })
})
