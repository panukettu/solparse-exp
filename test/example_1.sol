// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;
import {IBatchFacet} from "common/interfaces/IBatchFacet.sol";
import {__revert} from "kresko-lib/utils/Base.s.sol";
import {Errors} from "common/Errors.sol";
import {Modifiers} from "common/Modifiers.sol";
import {IPyth} from "vendor/pyth/IPyth.sol";

// solhint-disable no-empty-blocks, reason-string


library LibKek {
    function getVal(uint256 _val) internal view returns(uint256 out) {
        return _val;
    }
}
contract BatchFacet is IBatchFacet, Modifiers {
    struct Kek {
    uint256 val;
}
    using LibKek for Kek;
    Kek internal data = Kek({
        val: 1e18
    });
    /// @inheritdoc IBatchFacet
    function batchCall(bytes[] calldata _calls, bytes[] calldata _updateData) external payable usePyth(_updateData) {
        for (uint256 i; i < _calls.length; i++) {
            (bool success, bytes memory retData) = address(this).delegatecall(_calls[i]);
            if (!success) {
                __revert(retData);
            }
        }
    }

    /// @inheritdoc IBatchFacet
    function batchStaticCall(
        bytes[] calldata _staticCalls,
        bytes[] calldata _updateData
    ) external payable returns (uint256 timestamp, bytes[] memory results) {
        try this.batchCallToError(_staticCalls, _updateData) {
            revert();
        } catch Error(string memory reason) {
            revert(reason);
        } catch Asd(uint256 code) {
            revert Errors.Panicked(code);
        } catch (bytes memory errorData) {
            if (msg.value != 0) payable(msg.sender).transfer(msg.value);
            return this.decodeErrorData(errorData);
        }
    }

    /// @inheritdoc IBatchFacet
    function batchCallToError(
        bytes[] calldata _calls,
        bytes[] calldata _updateData
    ) external payable usePyth(_updateData) returns (uint256, bytes[] memory results) {
        results = new bytes[](_calls.length);

        for (uint256 i; i < _calls.length; i++) {
            (bool success, bytes memory returnData) = address(this).delegatecall(_calls[i]);
            if (!success) {
                __revert(returnData);
            }
            results[i] = returnData;
        }

        revert Errors.BatchResult(block.timestamp, results);
    }

    /// @inheritdoc IBatchFacet
    function decodeErrorData(bytes calldata _errorData) external pure returns (uint256 timestamp, bytes[] memory results) {
        return abi.decode(_errorData[4:], (uint256, bytes[]));
    }
}

function decodeErrorData(bytes calldata _errorData) pure returns (uint256 timestamp, bytes[] memory results) {
   (timestamp, results) = abi.decode(_errorData[4:], (uint256, bytes[]));

    uint256 val = data.getVal();

    return (val,results);
}