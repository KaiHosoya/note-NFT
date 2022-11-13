async function main() {
  // Grab the contract factory 
  const NoteMarketplace = await ethers.getContractFactory("NoteMarketplace");

  // Start deployment, returning a promise that resolves to a contract object
  const noteMarketplace = await NoteMarketplace.deploy(); // Instance of the contract 
  console.log("Contract deployed to address:", noteMarketplace.address);
}

main()
 .then(() => process.exit(0))
 .catch(error => {
   console.error(error);
   process.exit(1);
 });