#include <iostream>
#include <fstream>

int main(int argc, char* argv[])
{
	std::string ifile(argv[1]);
	std::string ofile(argv[2]);

	std::ofstream outFile(ofile);
	std::string line;

	std::string maintenance_on("  'maintenance' => true,");

	std::ifstream inFile(ifile);
	while(getline(inFile, line))
	{
		if (line.find("'maintenance' => false,") != std::string::npos)
		{
			outFile << maintenance_on << std::endl;
		}
		else
		{
			outFile << line << std::endl;
		}
	}
	outFile.close();
	inFile.close();

	return 0;
}
