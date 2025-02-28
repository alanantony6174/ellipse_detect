#include <iostream>
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
        std::cout << "[Usage]: testdetect [image_dir1] [image_dir2] [image_dir3] ..." << std::endl;
        return -1;
    }

    for (int i = 1; i < argc; ++i) {
        cv::Mat board = cv::imread(argv[i]);
        cv::Mat image = cv::imread(argv[i], cv::IMREAD_GRAYSCALE);
        
        if (board.empty() || image.empty()) {
            std::cerr << "Error: Could not read image " << argv[i] << std::endl;
            continue;
        }
        
        cv::imshow("Original Image", image);
        
        vector<shared_ptr<Ellipse>> ells;
        int row = image.rows;
        int col = image.cols;
        double width = 2.0;
        
        FuncTimerDecorator<int>("detectEllipse")(detectEllipse, image.data, row, col, ells, NONE_POL, width);
        
        cout << "Found " << ells.size() << " ellipse(s) in " << argv[i] << endl;
        
        for (size_t j = 0; j < ells.size(); ++j) {
            auto ell = ells[j];
            
            cout << "Ellipse " << j + 1 << ":\n";
            cout << "  Center: (" << ell->o.x << ", " << ell->o.y << ")\n";
            cout << "  Axes: (" << ell->a << " x " << ell->b << ")\n";
            cout << "  Rotation Angle: " << rad2angle(PI_2 - ell->phi) << " degrees\n";
            cout << "  Goodness: " << ell->goodness << "\n";
            cout << "  Polarity: " << ell->polarity << "\n";
            cout << "  Coverage Angle: " << ell->coverangle << " degrees\n";

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

        cv::imshow("Detected Result", board);
        cv::waitKey(0);
    }
    return 0;
}
