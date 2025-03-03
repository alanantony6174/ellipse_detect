#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include "opencv2/imgcodecs.hpp"
#include "opencv2/highgui/highgui.hpp"
#include "opencv2/imgproc/imgproc.hpp"
#include "ellipse_detection/types.hpp"
#include "ellipse_detection/detect.h"

using namespace std;
using namespace zgh;

int main(int argc, char* argv[]) {
    if (argc <= 1) {
        cerr << "Error: Usage testdetect [image_path1] [image_path2] ..." << endl;
        return -1;
    }
    
    for (int i = 1; i < argc; ++i) {
        cv::Mat board = cv::imread(argv[i]);
        cv::Mat image = cv::imread(argv[i], cv::IMREAD_GRAYSCALE);
        
        if (board.empty() || image.empty()) {
            cerr << "Error: Could not read image " << argv[i] << endl;
            continue;
        }

        vector<shared_ptr<Ellipse>> ells;
        int row = image.rows;
        int col = image.cols;
        double width = 2.0;

        FuncTimerDecorator<int>("detectEllipse")(detectEllipse, image.data, row, col, ells, NONE_POL, width);

        string filename = string(argv[i]).substr(string(argv[i]).find_last_of("/") + 1);
        string output_path = "/app/results/" + filename + "_detected.png";
        string result_txt_path = "/app/results/" + filename + "_result.txt";

        ofstream result_file(result_txt_path);
        if (!result_file.is_open()) {
            cerr << "Error: Could not write to " << result_txt_path << endl;
            continue;
        }

        result_file << "filename: " << filename << endl;
        result_file << "ellipse_count: " << ells.size() << endl;

        for (size_t j = 0; j < ells.size(); ++j) {
            auto ell = ells[j];
            result_file << "Ellipse " << j + 1 << ":" << endl;
            result_file << "  Center: (" << ell->o.x << ", " << ell->o.y << ")" << endl;
            result_file << "  Axes: (" << ell->a << " x " << ell->b << ")" << endl;
            result_file << "  Rotation Angle: " << rad2angle(PI_2 - ell->phi) << " degrees" << endl;
            result_file << "  Goodness: " << ell->goodness << endl;
            result_file << "  Polarity: " << ell->polarity << endl;
            result_file << "  Coverage Angle: " << ell->coverangle << " degrees" << endl;

            cv::ellipse(board,
                        cv::Point(ell->o.y, ell->o.x),
                        cv::Size(ell->a, ell->b),
                        rad2angle(PI_2 - ell->phi),
                        0,
                        360,
                        cv::Scalar(0, 255, 0),
                        width,
                        8,
                        0);
        }

        cv::imwrite(output_path, board);
        result_file << "output_image_path: " << output_path << endl;
        result_file.close();
    }

    return 0;
}
